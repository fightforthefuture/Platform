web: bundle exec rails server puma -p ${PORT} -e production
clock: bundle exec clockwork lib/tasks/clock.rb
worker: QUEUE=$DEFAULT_QUEUE bundle exec rake jobs:work
blaster: QUEUE=$BLASTER_QUEUE bundle exec rake jobs:work
high_priority: QUEUES=$LIST_CUTTER_QUEUE,$HIGH_QUEUE bundle exec rake jobs:work
