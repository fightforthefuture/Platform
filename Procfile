web: bundle exec rails server puma -p ${PORT} -e production
clock: bundle exec clockwork lib/tasks/clock.rb
worker: QUEUE=$DEFAULT_QUEUE bundle exec rake jobs:work
list_cutter_blaster: QUEUE=$LIST_CUTTER_BLASTER_QUEUE bundle exec rake jobs:work
