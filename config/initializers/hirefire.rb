HireFire::Resource.configure do |config|
  config.dyno(:worker) do
    HireFire::Macro::Delayed::Job.queue(:default, mapper: :active_record)
  end

  config.dyno(:high_priority) do
    HireFire::Macro::Delayed::Job.queue(:high, mapper: :active_record)
  end

  config.dyno(:blaster) do
    HireFire::Macro::Delayed::Job.queue(:blaster, mapper: :active_record)
  end
end