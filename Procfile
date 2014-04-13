web: bundle exec rails server puma -p ${PORT} -e production
clock: bundle exec clockwork lib/tasks/clock.rb
worker: QUEUE=$DEFAULT_QUEUE bundle exec rake jobs:work
blaster: QUEUE=blaster bundle exec rake jobs:work
high_priority: QUEUES=high,list_cutter bundle exec rake jobs:work
