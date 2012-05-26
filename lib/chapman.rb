require 'chapman/version'
require 'chapman/exceptions'
require 'chapman/worker'

STDOUT.sync = true

module Chapman
  extend self

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

    # start a worker thread
    thread_count.times do
      w = Chapman::Worker.new()
      t = Thread.new { w.work(jobs) }
      running << {thread: t, worker: w}
    end

    # keep them alive
    while not soft_quit?
      maintain_workers
      sleep 1
    end

    murder_workers!

    reap_workers

    log "SEPPUKU!!"
  end

  def maintain_workers
    running.each_with_index do |runner, index|
      if not runner[:thread].alive?
        w = Creeper::Worker.new()
        t =  Thread.new do
          w.work(jobs)
      end
        running[index] = {thread: t, worker: w}
      end
    end
  end

  def murder_workers!
    running.each do |runner|
      if runner[:worker].job_in_progress?
        log "Murder [scheduling]"
      else
        log "Murder [now]"
        runner[:thread].kill
      end
    end
  end

  def reap_workers
    running.each do |runner|
      runner[:thread].join
    end
  end

  def log(msg)
    puts msg
  end

  def log_error(msg)
    STDERR.puts msg
  end

  def beanstalk_url
    return @@url if defined?(@@url) and @@url
    ENV['BEANSTALK_URL'] || 'beanstalk://localhost/'
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

  def reset!
    @@soft_quit       = false
    @@running         = []
    @@handlers        = nil
    @@before_handlers = nil
    @@error_handler   = nil
  end
end