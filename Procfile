web: bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec sidekiq -c 3 -q default -q mailers
