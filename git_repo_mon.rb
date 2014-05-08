require 'serialport'
require 'io/console'
require 'listen'

def get_root_directory directory
  Dir.chdir(directory) do 
    `git rev-parse`
    return nil unless $?
    
    if `git rev-parse --is-inside-git-dir 2>/dev/null`.strip == 'true'
      return get_root_directory directory + '/..'
    end
  end
  
  Dir.chdir(directory) { `git rev-parse --show-toplevel 2>/dev/null` }.strip
end

def get_branch
  `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
end

def get_unpushed_commits
  `git rev-list @{u}.. --count 2>/dev/null`.to_i
end

def get_unmerged_commits
  `git rev-list ..FETCH_HEAD --count 2>/dev/null`.to_i
end

def get_changed_file_count
  `git status --p 2>/dev/null | wc -l | tr -d ' '`.to_i
end

def get_user_name
  `git config user.name`.strip
end

def get_last_commit(user_name)
  `git log --author="#{user_name}" --pretty=format:%cr -1 2>/dev/null` || 'never'
end

def with_port
  if ARGV[0].nil? || ARGV[0].empty?
    yield IO.console
    
  else
    SerialPort.open(ARGV[0], 9600, 8, 1, SerialPort::NONE) do |port|
      sleep 2
      yield port
    end
  end
end

def ignored_directories
  directories = Listen::Silencer::DEFAULT_IGNORED_DIRECTORIES
    .reject{|filter| filter == '.git'}
    .map{|e| Regexp.escape(e)}
    .join('|')
    
    %r{^(?:#{directories})(/|$)}
end

with_port do |port|
  listener = Listen.to(Dir.pwd, ignore!: ignored_directories) do |modified, added, removed|
    directory = removed.concat(added).concat(modified).last
    directory = File.dirname directory
    directory = get_root_directory(directory)
    next if directory.nil? || directory.empty?

    Dir.chdir(directory) do
      folder = Dir.pwd.split(File::SEPARATOR).last
      sleep 0.05
      port.print "#{folder[0..20].center(20)}\n"

      status = "u+#{get_unpushed_commits}-#{get_unmerged_commits}"
      branch_length = 19 - status.length
      branch = get_branch[0, branch_length].ljust(branch_length)
      message = "#{branch} #{status}"
      sleep 0.05
      port.print "#{message}\n"

      user_name = get_user_name

      last_commit = get_last_commit user_name
      change_count = get_changed_file_count.to_s.ljust(18 - last_commit.length)
      port.write 0x3.chr
      sleep 0.05
      port.print "#{change_count} #{last_commit}\n"

      sleep 0.05
      port.print "#{user_name[0..20].center(20)}\n"
    end
  end

  listener.start # not blocking
  sleep
end