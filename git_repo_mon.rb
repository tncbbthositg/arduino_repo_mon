require 'serialport'

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

SerialPort.open(ARGV[0], 9600, 8, 1, SerialPort::NONE) do |port|
  sleep 2

  while true
    status = "u+#{get_unpushed_commits}-#{get_unmerged_commits}"
    branch_length = 19 - status.length
    branch = get_branch[0, branch_length].ljust(branch_length)
    message = "#{branch} #{status}"
    port.print "#{message}\n"

    user_name = get_user_name

    last_commit = get_last_commit user_name
    change_count = get_changed_file_count.to_s.ljust(18 - last_commit.length)
    port.write 0x3.chr
    port.print "#{change_count} #{last_commit}\n\n"

    port.print "#{user_name[0..20].center(20)}\n"
    sleep 10
  end
end