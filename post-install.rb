#--
# Copyright 2006 by Chad Fowler, Rich Kilmer, Jim Weirich and others.
# All rights reserved.
# See LICENSE.txt for permissions.
#++

require 'rbconfig'

def remove_stubs
  is_apparent_stub = lambda { |path|
    File.read(path, 40) =~ /^# This file was generated by RubyGems/ and
      File.readlines(path).size < 20
  }
  puts %{
    As of RubyGems 0.8.0, library stubs are no longer needed.
    Searching $LOAD_PATH for stubs to optionally delete (may take a while)...
  }.gsub(/^ */, '')
  gemfiles = Dir.glob("{#{($LOAD_PATH).join(',')}}/**/*.rb").collect {|file| File.expand_path(file)}.uniq
  puts "...done."
  seen_stub = false
  gemfiles.each do |file|
    unless File.directory?(file)
      if is_apparent_stub[file]
        unless seen_stub
          puts "\nRubyGems has detected stubs that can be removed.  Confirm their removal:"
        end
        seen_stub = true
        print "  * remove #{file}? [y/n] "
        answer = gets
        if answer =~ /y/i then
          File.unlink(file)
          puts "        (removed)"
        else
          puts "        (skipping)"
        end
      end
    end
  end
  if seen_stub
    puts "Finished with library stubs."
  else
    puts "No library stubs found."
  end
  puts
end

def install_windows_batch_files
  bindir = Config::CONFIG['bindir']
  ruby_install_name = Config::CONFIG['ruby_install_name']
  is_windows_platform = Config::CONFIG["arch"] =~ /dos|win32/i
  require 'find'
  Find.find('bin') do |f|
    next if f =~ /\bCVS\b/
    next if f =~ /~$/
    next if FileTest.directory?(f)
    next if f =~ /\.rb$/
    next if File.basename(f) =~ /^\./
    source = f
    target = File.join(bindir, File.basename(f))
    if is_windows_platform
      File.open(target+".cmd", "w") do |file|
	ruby_cmd = Gem.ruby rescue 'ruby'
        file.puts %{@"#{ruby_cmd}" "#{target}" %1 %2 %3 %4 %5 %6 %7 %8 %9}
      end
    end
  end
end

def install_sources
  $: << "lib"
  require 'rubygems'
  Gem::manage_gems
  Dir.chdir("pkgs/sources") do
    load "sources.gemspec"
    spec = Gem.sources_spec
    gem_file = Gem::Builder.new(spec).build
    Gem::Installer.new(gem_file).install(true, Gem.dir, false)
  end
end

install_windows_batch_files
remove_stubs
install_sources

