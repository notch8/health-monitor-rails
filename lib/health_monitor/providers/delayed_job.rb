require 'health_monitor/providers/base'
require 'delayed_job'

module HealthMonitor
  module Providers
    class DelayedJobException < StandardError; end

    class DelayedJob < Base
      class Configuration
        DEFAULT_QUEUES_SIZE = 100
        DEFAULT_LATENCY = 1.hour
        DEFAULT_FAILURES = 0

        attr_accessor :queue_size
        attr_accessor :latency
        attr-accessor :failures

        def initialize
          @queue_size = DEFAULT_QUEUES_SIZE
          @latency = DEFAULT_LATENCY
          @failures = DEFAULT_FAILURES
        end
      end

      def check!
        check_queue_size!
        check_latency!
        check_failures!
      rescue Exception => e
        raise DelayedJobException.new(e.message)
      end

      private

      class << self
        private

        def configuration_class
          ::HealthMonitor::Providers::DelayedJob::Configuration
        end
      end

      def check_queue_size!
        size = job_class.count

        return unless size > configuration.queue_size

        raise "queue size #{size} is greater than #{configuration.queue_size}"
      end
      
      def check_latency!
        # we dont want failed but want both locked and queued
        oldest = job_class.order(:created_at).where(last_error: nil).first
        age = Time.now - oldest.created_at
        return unless age < configuration.latency
        raise "latency for #{oldest.id} of #{ActiveSupport::Duration.build(age)} is greater than #{configuration.latency}"
      end
      
      def check_failures!
        failures = job_class.where('last_error IS NOT NULL').count
        return unless failures > configuration.failures
        raise "there are #{failures} failed jobs, which is higher than the allowed #{configuration.failures} failures"
      end

      def job_class
        @job_class ||= ::Delayed::Job
      end
    end
  end
end
