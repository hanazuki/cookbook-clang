#
# Cookbook Name:: clang
# Recipe:: source
#
# Copyright (C) 2014 Kasumi Hanazuki
#

include_recipe 'subversion'

directory 'llvm-source' do
  action :create
  path node.clang.source.directory
  recursive true
end

tagname = llvm_tagname node[:clang][:version]

subversion 'llvm' do
  action :sync
  repository "#{node.clang.source.repository}/llvm/#{tagname}"
  destination "#{node.clang.source.directory}"
end

subversion 'llvm-clang' do
  action :sync
  repository "#{node.clang.source.repository}/cfe/#{tagname}"
  destination "#{node.clang.source.directory}/tools/clang"
end

subversion 'llvm-compiler-rt' do
  action :sync
  repository "#{node.clang.source.repository}/compiler-rt/#{tagname}"
  destination "#{node.clang.source.directory}/projects/compiler-rt"
end
