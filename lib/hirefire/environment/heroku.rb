# encoding: utf-8

#require 'heroku'

module HireFire
  module Environment
    class Heroku < Base

      @@workers_cache = nil
      @@last_checked = nil

      private

      ##
      # Either retrieves the amount of currently running workers,
      # or set the amount of workers to a specific amount by providing a value
      #
      # @overload workers(amount = nil)
      #   @param [Fixnum] amount will tell heroku to run N workers
      #   @return [nil]
      # @overload workers(amount = nil)
      #   @param [nil] amount
      #   @return [Fixnum] will request the amount of currently running workers from Heroku
      def workers(amount = nil)

        #
        # Returns the amount of Delayed Job
        # workers that are currently running on Heroku
        if amount.nil?
          #return client.info(ENV['APP_NAME'])[:workers].to_i
          if @@last_checked.nil? || @@workers_cache.nil? || @@last_checked < 5.minutes.ago
            HireFire::Logger.message("get workers: Heroku API")
            @@last_checked = Time.now
            @@workers_cache = @client.formation.list(ENV['APP_NAME']).select{|p| p["type"] == "worker"}.sum{|p| p["quantity"]}
            return @@workers_cache
          else
            HireFire::Logger.message("get workers: Cache")
            return @@workers_cache
          end
        end

        ##
        # Sets the amount of Delayed Job
        # workers that need to be running on Heroku
        #client.set_workers(ENV['APP_NAME'], amount)
        @@last_checked = Time.now
        @@workers_cache = amount
        HireFire::Logger.message("set workers: Heroku API -> #{amount}")
        return @client.formation.update(ENV['APP_NAME'], "worker",{:quantity=>amount,:size=>"1X"})

      rescue RestClient::Exception
        # Heroku library uses rest-client, currently, and it is quite
        # possible to receive RestClient exceptions through the client.
        HireFire::Logger.message("Worker query request failed with #{ $!.class.name } #{ $!.message }")
        nil
      end

      ##
      # @return [Heroku::Client] instance of the heroku client
      def client
        #@client ||= ::Heroku::Client.new(
        #  ENV['HIREFIRE_EMAIL'], ENV['HIREFIRE_PASSWORD']
        #)
        @client ||= PlatformAPI.connect(ENV['HEROKU_API_KEY'])
      end

    end
  end
end
