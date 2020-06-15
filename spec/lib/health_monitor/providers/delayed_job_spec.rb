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

    context 'almost failing' do
      context 'the oldest failure is less than the failed latency option' do
        let(:job) { OpenStruct.new(id: 1, run_at: (Time.now - 29.minutes), last_error: 'error') }
        before do
          described_class.configure do |config|
            config.latency = 5.hours
            config.failures = 50
            config.failed_latency = 30.minutes
          end

          job_list = [job]
          allow(job_list).to receive(:order).and_return(job_list)
          allow(Delayed::Job).to receive(:where).and_return(job_list)
        end

        it 'successfully checks' do
          expect {
            subject.check!
          }.not_to raise_error
        end
      end
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

      context 'the oldest failure is greater than the failed latency option' do
        let(:job) { OpenStruct.new(id: 2, run_at: (Time.now - 30.minutes), last_error: 'error') }
        before do
          described_class.configure do |config|
            config.latency = 5.hours
            config.failures = 50
            config.failed_latency = 30.minutes
          end

          job_list = [job]
          allow(job_list).to receive(:order).and_return(job_list)
          allow(Delayed::Job).to receive(:where).and_return(job_list)
        end

        it 'fails check!' do
          expect {
            subject.check!
          }.to raise_error(HealthMonitor::Providers::DelayedJobException, /one or more jobs has been failed for [\d\.]+ which is greater than 1800/)
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
end
