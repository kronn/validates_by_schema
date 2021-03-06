# encoding: utf-8
require 'spec_helper'

describe 'validates by schema' do
  let(:attributes) do
    { name: 'Secret',
      model: 'secret-42',
      description: 'Life, the Universe, Everything',
      wheels: 4,
      doors: 2,
      price: 4242.42,
      cost: 42.42,
      completion: 0.424,
      rating: 42.4242,
      score: 4242.42,
      published_at: Time.now.to_datetime,
      invented_on: Time.now.to_date,
      startup_time: 1.hour.ago,
      shutdown_time: 4.hours.from_now,
      enabled: true,
      data: 'the question'.unpack('b*').to_s,
      parent: Widget.new,
      kind: 'one',
      list: ['abc']}
  end

  context 'plain' do
    subject { Contraption.new attributes }

    context 'validates columns of type' do
      context :string do
        it { should_not validate_presence_of(:name) }
        it { should validate_length_of(:name).is_at_most(50) }
        it { should validate_presence_of(:model) }
        if ENV['DB'] == 'mysql'
          it { should validate_length_of(:model).is_at_most(255) }
        end
      end

      context :text do
        it { should_not validate_presence_of(:description) }
        it { should_not validate_length_of(:description).is_at_most(10_000_000) }
      end

      context :primary_key do
        it { should_not validate_presence_of(:id) }
      end

      context :integer do
        it { should validate_presence_of(:wheels) }
        it { should validate_numericality_of(:wheels).only_integer }
        it { should allow_value(242_424).for(:wheels) }
        it { should allow_value(-242_424).for(:wheels) }
        if ENV['DB'] != 'mysql'
          it { should allow_value(2_147_483_647).for(:wheels) }
          it { should allow_value(-2_147_483_647).for(:wheels) }
          if ENV['DB'] != 'postgresql'
            it { should allow_value(10**100).for(:wheels) }
            it { should allow_value(-10**100).for(:wheels) }
          end
        end

        it { should_not validate_presence_of(:doors) }
        it { should validate_numericality_of(:doors).only_integer }
        it { should allow_value(32767).for(:doors) }
        it { should allow_value(-32767).for(:doors) }
        it { should_not allow_value(32768).for(:doors) }
        it { should_not allow_value(-32768).for(:doors) }
      end

      context :decimal do
        it { should_not validate_presence_of(:price) }
        it { should validate_numericality_of(:price) }
        it { should allow_value(-9_999.99).for(:price) }
        it { should allow_value(9_999.99).for(:price) }
        it { should_not allow_value(10_000).for(:price) }
        it { should_not allow_value(-10_000).for(:price) }

        it { should validate_presence_of(:cost) }
        it { should validate_numericality_of(:cost) }
        it { should allow_value(99.99).for(:cost) }
        it { should allow_value(-99.99).for(:cost) }
        it { should_not allow_value(100).for(:cost) }
        it { should_not allow_value(-100).for(:cost) }
      end

      context :float do
        it { should_not validate_presence_of(:rating) }
        it { should validate_numericality_of(:rating) }
        it { should allow_value(242_424.242424).for(:rating) }
        it { should allow_value(-5).for(:rating) }

        it { should validate_presence_of(:score) }
        it { should validate_numericality_of(:score) }
        it { should allow_value(242_424.242424).for(:score) }
        it { should allow_value(-5).for(:score) }
      end

      context :datetime do
        it { should_not validate_presence_of(:published_at) }
      end

      context :date do
        it { should_not validate_presence_of(:invented_on) }
      end

      context :time do
        it { should_not validate_presence_of(:startup_time) }
        it { should validate_presence_of(:shutdown_time) }
      end

      context :belongs_to do
        if !ActiveRecord::Base.belongs_to_required_by_default
          # belongs_to_required_by_default produces message 'must exist' instead of 'can't be blank'
          it { should validate_presence_of(:parent) }
        end

        it { should allow_value(Widget.new).for(:parent) }
        it { should_not allow_value(nil).for(:parent) }
      end

      context :enum do
        it { should validate_presence_of(:kind) }
        it { should allow_value('other').for(:kind) }
      end

      if ENV['DB'] == 'postgresql'
        context :array do
          it { should allow_value(['abc', 'def', 'ghi', 'jkl']).for(:list) }
          # this value will be rejected by the db, but the validation would require a custom
          # validator.
          it { should allow_value(['abcdef']).for(:list) }
        end
      end
    end
  end

  context 'with except' do
    subject { Gadget.new attributes }

    context 'does not validate passed columns' do
      context :string do
        it { should_not validate_presence_of(:name) }
        it { should validate_length_of(:name).is_at_most(50) }
      end

      context :integer do
        it { should_not validate_presence_of(:wheels) }
        it { should_not validate_numericality_of(:wheels) }
        it { should allow_value(242_424).for(:wheels) }
        it { should allow_value(-42_424).for(:wheels) }
        it { should allow_value(10**100).for(:wheels) }
        it { should allow_value(-10**100).for(:wheels) }
      end

      context :decimal do
        it { should_not validate_presence_of(:price) }
        it { should validate_numericality_of(:price) }
      end
    end
  end

  context 'with only' do
    subject { Gizmo.new attributes }

    context 'validate just passed columns' do
      context :string do
        it { should_not validate_presence_of(:name) }
        it { should validate_length_of(:name).is_at_most(50) }
      end

      context :integer do
        it { should validate_presence_of(:wheels) }
        it { should validate_numericality_of(:wheels).only_integer }
        it { should allow_value(242_424).for(:wheels) }
        it { should allow_value(-42_424).for(:wheels) }
        if ENV['DB'] != 'mysql'
          it { should allow_value(2_147_483_647).for(:wheels) }
          it { should allow_value(-2_147_483_647).for(:wheels) }
          if ENV['DB'] != 'postgresql'
            it { should allow_value(10**100).for(:wheels) }
            it { should allow_value(-10**100).for(:wheels) }
          end
        end
      end

      context :decimal do
        it { should_not validate_presence_of(:price) }
        it { should_not validate_numericality_of(:price) }
        it { should allow_value('1000000').for(:price) }
      end
    end
  end

  context 'subclass' do
    subject { SubContraption.new attributes }

    context 'performs validations as well' do
      context :string do
        it { should_not validate_presence_of(:name) }
        it { should validate_length_of(:name).is_at_most(50) }
        it { should validate_presence_of(:model) }
      end
    end
  end

  context 'multiple threads' do
    subject { Contraption.new attributes }

    it 'defines validations only once' do
      subject.list = nil
      subject.model = nil
      5.times do
        Thread.new do
          Contraption.new.valid?
        end
      end

      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq(["Model can't be blank"])
    end
  end

  context 'reset_column_information' do
    subject { Contraption.new attributes }

    it 'does not duplicate validations' do
      subject.list = nil
      expect(subject).to be_valid

      Contraption.reset_column_information

      subject.model = nil
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq(["Model can't be blank"])
    end
  end
end
