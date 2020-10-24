#!/usr/bin/env ruby

require 'getoptlong'

def checked_run(*args, dir: nil)
  command = args.join(' ') 
  if !dir.nil?
   command = "cd #{dir} && #{command}" 
  end 
#  puts "Running #{command}" 
  system command
end

def get_args
 opts = GetoptLong.new(
   ['--zip', '-z', GetoptLong::NO_ARGUMENT],
   ['--unzip', '-u', GetoptLong::NO_ARGUMENT],
   ['--projpath', '-p', GetoptLong::REQUIRED_ARGUMENT],
   ['--archpath', '-a', GetoptLong::REQUIRED_ARGUMENT],
   ['--help', '-h', GetoptLong::NO_ARGUMENT]
 )
 args = {}
 opts.each do |opt, arg|
  case opt
   when '--zip'
    args[:mode] = :zip
   when '--unzip'
    args[:mode] = :unzip
   when '--projpath'
    args[:projpath] = arg
   when '--archpath'
    args[:archpath] = arg
   when '--help'
    puts "Приложение для бэкапа данных используемых сервисов принимает на вход 3 аргумента
    --zip или --unzip (-z/-u) - для архивирования / распаковки бэкапа;
    --projpath (-p) path/to/proj - путь до корневой директории проекта;
    --archpath (-a) path/to/arch.tar - путь до архива с бэкапом.
    пример: -z -p path/to/proj -a path/to/arch.tar"
    exit(0)
   end
  end
  args
end 

def zip(projpath, archpath, name)
 checked_run('sudo', 'mkdir', "/tmp/backup")
 checked_run('sudo', 'cp', '-r', File.join(projpath, 'gitea', 'data'), "/tmp/backup/gitea")
 checked_run('sudo', 'cp', '-r', File.join(projpath, 'gocd', 'data'), "/tmp/backup/gocd")
 checked_run('sudo', 'cp', '-r', File.join(projpath, 'taiga', 'data'), "/tmp/backup/taiga")
 checked_run('sudo', 'tar', '-cvf', File.join(archpath, name), "/tmp/backup")
 checked_run('sudo', 'rm', '-rf', "/tmp/backup")
end

def unzip(projpath, archpath)
  checked_run('sudo', 'rm', '-rf', File.join(projpath, 'gitea', 'data'))
  checked_run('sudo', 'rm', '-rf', File.join(projpath, 'gocd', 'data'))
  checked_run('sudo', 'rm', '-rf', File.join(projpath, 'taiga', 'data'))
  checked_run('sudo', 'tar', '-xvf', archpath, '-C', File.join(projpath, 'backup'))
  checked_run('sudo', 'cp', '-r', File.join(projpath, 'backup', 'tmp', 'backup', 'gitea'), File.join(projpath, 'gitea', 'data'))
  checked_run('sudo', 'cp', '-r', File.join(projpath, 'backup', 'tmp', 'backup', 'gocd'), File.join(projpath, 'gocd', 'data'))
  checked_run('sudo', 'cp', '-r', File.join(projpath, 'backup', 'tmp', 'backup', 'taiga'), File.join(projpath, 'taiga', 'data'))
  checked_run('sudo', 'rm', '-rf', File.join(projpath, 'backup', 'tmp'))
end

if __FILE__ == $0
  args = get_args
  if args.size != 3
    puts "Введено неверное количество аргументов! (#{args.size} вместо 3):
    --zip или --unzip (-z/-u) - для архивирования / распаковки бэкапа;
    --projpath (-p) - путь до корневой директории проекта;
    --archpath (-a) - путь с названием архива с бэкапом.
    пример: -z -p path/to/proj -a path/to/arch.tar"
    exit(1)
  end
  projpath = File.expand_path(args[:projpath])
  archpath = File.expand_path(args[:archpath])
  time = Time.new
  name = "#{time.strftime("%H_%M_%S_%d_%m_%Y")}_backup.tar"
  puts name
  if args[:mode] == :zip
    zip(projpath, archpath, name)
  else
    unzip(projpath, archpath)
  end
end  
