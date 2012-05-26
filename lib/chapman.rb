require "chapman/version"
require 'beanstalk-client'
require 'json'
require 'uri'
require 'timeout'

STDOUT.sync = true

module Chapman
  extend self

  def connect(url)
    @@url = url
    beanstalk
  end

  def enqueue(job, args={}, opts={})
    pri   = opts[:pri]   || 65536
    delay = [0, opts[:delay].to_i].max  
    ttr   = opts[:ttr]   || 120
    beanstalk.use job
    beanstalk.put [ job, args ].to_json, pri, delay, ttr
  rescue Beanstalk::NotConnected => e
    failed_connection(e)
  end

  def job(j, &block)
    @@handlers ||= {}
    @@handlers[j] = block
  end

  def before(&block)
    @@before_handlers ||= []
    @@before_handlers << block
  end

  def error(&blk)
    @@error_handler = blk
  end

  def running
    @@running ||= []
  end

  def soft_quit?
    @@soft_quit ||= false
  end

  def soft_quit=(soft_quit)
    @@soft_quit = soft_quit
  end

  def work(jobs=nil, thread_count=1)
    thread_count.times do
      w = Creeper::Worker.new()
      t =  Thread.new do
        w.work(jobs)
      end
      running << {thread: t, worker: w}
    end

    while not soft_quit?
      running.each_with_index do |runner, index|
        if not runner[:thread].alive?
          w = Creeper::Worker.new()
          t =  Thread.new do
            w.work(jobs)
          end
          running[index] = {thread: t, worker: w}
        end
      end
      sleep 1
    end
    running.each do |runner|
      if runner[:worker].job_in_progress?
        log "Murder [scheduling]"
        runner[:worker].soft_quit = true  
      else
        log "Murder [now]"
        runner[:thread].kill
      end
    end
    running.each do |runner|
      runner[:thread].join
    end
    log "SEPPUKU!!"
  end

  def failed_connection(e)
    log_error exception_message(e)
    log_error "*** Failed connection to #{beanstalk_url}"
    log_error "*** Check that beanstalkd is running (or set a different BEANSTALK_URL)"
    exit 1
  end

  def log(msg)
    puts msg
  end

  def log_error(msg)
    STDERR.puts msg
  end

  def beanstalk
    @@beanstalk ||= Beanstalk::Pool.new(beanstalk_addresses)
  end

  def beanstalk_url
    return @@url if defined?(@@url) and @@url
    ENV['BEANSTALK_URL'] || 'beanstalk://localhost/'
  end

  class BadURL < RuntimeError; end

  def beanstalk_addresses
    uris = beanstalk_url.split(/[\s,]+/)
    uris.map {|uri| beanstalk_host_and_port(uri)}
  end

  def beanstalk_host_and_port(uri_string)
    uri = URI.parse(uri_string)
    raise(BadURL, uri_string) if uri.scheme != 'beanstalk'
    "#{uri.host}:#{uri.port || 11300}"
  end

  def exception_message(e)
    msg = [ "Exception #{e.class} -> #{e.message}" ]

    base = File.expand_path(Dir.pwd) + '/'
    e.backtrace.each do |t|
      msg << "   #{File.expand_path(t).gsub(/#{base}/, '')}"
    end

    msg.join("\n")
  end

  def all_jobs
    @@handlers.keys
  end

  def job_handlers
    @@handlers ||= {}
  end

  def before_handlers
    @@before_handlers ||= []
  end

  def error_handler
    @@error_handler ||= nil
  end

  def clear!
    @@soft_quit = false
    @@running = []
    @@handlers = nil
    @@before_handlers = nil
    @@error_handler = nil
  end
end