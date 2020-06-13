require 'spec_helper'

describe HealthMonitor::Providers::DelayedJob do
  describe HealthMonitor::Providers::DelayedJob::Configuration do
    describe 'defaults' do
      it { expect(described_class.new.queue_size).to eq(HealthMonitor::Providers::DelayedJob::Configuration::DEFAULT_QUEUES_SIZE) }
    end
  end

  subject { described_class.new(request: test_request) }

  describe '#provider_name' do
    it { expect(described_class.provider_name).to eq('DelayedJob') }
  end

  describe '#check!' do
    before do
      described_class.configure
      Providers.stub_delayed_job
      Providers.stub_delayed_job_where
      Providers.stub_delayed_job_order
    end

    it 'succesfully checks' do
      expect {
        subject.check!
      }.not_to raise_error
    end

    context 'failing' do
      context 'queue_size' do
        before do
          Providers.stub_delayed_job_queue_size_failure
        end

        it 'fails check!' do
          expect {
            subject.check!
          }.to raise_error(HealthMonitor::Providers::DelayedJobException)
        end
      end
    end
  end

  describe '#configurable?' do
    it { expect(described_class).to be_configurable }
  end

  describe '#configure' do
    before do
      described_class.configure
    end

    let(:queue_size) { 123 }

    it 'queue size can be configured' do
      expect {
        described_class.configure do |config|
          config.queue_size = queue_size
        end
      }.to change { described_class.new.configuration.queue_size }.to(queue_size)
    end
  end

  describe '.check_failed_latency' do
    context 'the oldest failure is greater than the failed latency option' do
      before do
        described_class.configure
        Providers.stub_delayed_job
      end

      # let(:job) { run_at: Time.now - 3 hours, last_error: 'error' }
      # let(:run_at) { Time.now - 3.hours }
      # let(:last_error) { 'error' }
      # job { described_class.new(run_at: run_at, last_error: last_error) }
      # let(:job) { described_class.new(run_at: Time.now - 3.hours, last_error: 'error') }
      # let(:job) { described_class.new() }

      it 'raises an error with the default failed latency' do
        # job = job.delay(run_at)
        binding.pry

        expect {
          # job.check_failed_latency!
          job.send(:check_failed_latency!)
        }.to raise_error(HealthMonitor::Providers::DelayedJobException)
      end
    end

    # context 'the oldest failure is less than the failed latency option' do
    #   it 'does not raise an error with the default failed latency' do
    #   end
    # end

  end

end
