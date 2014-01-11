#
# Cookbook Name:: clang
# Recipe:: default
#
# Copyright (C) 2014 Kasumi Hanazuki
#

require 'shellwords'

include_recipe 'clang::source'
include_recipe 'build-essential'

build_directory = node.clang.build.directory

directory 'llvm-build' do
  action :create
  path build_directory
end


execute "configure:clang-llvm" do
  action :run
  cwd build_directory

  configure_script = "#{node.clang.source.directory}/configure".shellescape
  configure_flags =
    [
     node.clang.prefix && ['--prefix', node.clang.prefix],
     node.clang.build.optimized ? '--enable-optimized' : '--disable-optimized',
     node.clang.build.assertions ? '--enable-assertions' : '--disable-assertions',
     node.clang.build.configure_options,
    ].flatten.compact.map(&:to_s)

  command "#{configure_script} #{configure_flags.shelljoin}"

  not_if do
    config_status = "#{build_directory}/config.status"
    if ::File.exists?(config_status)
      begin
        `#{config_status.shellescape} -V`.split("\n").any? do |line|
          if /with options "(.*)"/ =~ line
            Chef::Log::info("Last configure options: #{$1}")
            $1.shellsplit == configure_flags
          end
        end
      rescue
        Chef::Log::warn($!.to_s)
        false
      end
    end
  end

  subscribes :run, 'subversion[llvm]'
  subscribes :run, 'subversion[llvm-clang]'
  subscribes :run, 'subversion[llvm-compiler-rt]'
end

if node.clang.build.workaround_sw_vers
  # workaround for a bug in compiler-rt's Makefile around LLVM 3.2

  directory 'llvm-workaround' do
    action :create
    path "#{build_directory}/workaround"
  end

  file 'llvm-workaround-sw_vers' do
    action :create
    path "#{build_directory}/workaround/sw_vers"
    mode 0755

    content <<EOS
#!/bin/sh
echo "dummy sw_vers"
EOS
  end
end

execute "build:clang-llvm" do
  action :run
  cwd build_directory

  make_flags =
    [
     node.clang.build.jobs && ['-j', node.clang.build.jobs],
     node.clang.build.make_options,
    ].flatten.compact.map(&:to_s)

  make_command =
    ["make #{make_flags.shelljoin}",
     node.clang.build.skip_tests ? nil : "make #{make_flags.shelljoin} check-all",
     "make #{make_flags.shelljoin} install"]

  if node.clang.build.workaround_sw_vers
    make_command.unshift %Q{export PATH="$PATH:#{build_directory}/workaround"}
  end

  command make_command.compact.join(' && ')

  not_if do
    %w[clang clang++].all? do |prog|
      ::File.exists?("#{node.clang.prefix}/bin/#{prog}")
    end
  end

  subscribes :run, 'execute[configure:clang-llvm]'
end
