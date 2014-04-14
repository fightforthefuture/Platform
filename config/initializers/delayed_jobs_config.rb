# config/initializers/delayed_job_config.rb
Delayed::Worker.backend = :active_record
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 3
Delayed::Worker.max_attempts = 2
Delayed::Worker.max_run_time = 20.minutes
Delayed::Worker.delay_jobs = true
Delayed::Worker.default_queue_name = ENV['DEFAULT_QUEUE'] || "default"


module QueueConfigs
  BLASTER_QUEUE = ENV['BLASTER_QUEUE'] || "blaster"
  LIST_CUTTER_QUEUE = ENV['LIST_CUTTER_QUEUE'] || "list_cutter"
  HIGH_QUEUE = ENV['LIST_CUTTER_BLASTER_QUEUE'] || "high"
end
