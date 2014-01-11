
def llvm_tagname(version)
  case version.to_s
  when /^(\d)\.(\d)$/
    if "#{$1}#{$2}".to_i <= 28
      "tags/RELEASE_#{$1}#{$2}"
    else
      "tags/RELEASE_#{$1}#{$2}/final"
    end
  when /^(\d)\.(\d)-?(rc\d+)$/
    "tags/RELEASE_#{$1}#{$2}/rc#{$3}"
  when 'svn', 'trunk'
    "trunk"
  else
    version.to_s
  end
end
