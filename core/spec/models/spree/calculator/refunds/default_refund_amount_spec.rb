require 'rails_helper'
require 'shared_examples/calculator_shared_examples'

RSpec.describe Spree::Calculator::Returns::DefaultRefundAmount, type: :model do
  let(:line_item_quantity) { 2 }
  let(:line_item_price) { 100.0 }
  let(:line_item) { create(:line_item, price: line_item_price, quantity: line_item_quantity) }
  let(:shipment) { create(:shipment, order: order) }
  let(:inventory_unit) { build(:inventory_unit, shipment: shipment, line_item: line_item) }
  let(:return_item) { build(:return_item, inventory_unit: inventory_unit ) }
  let(:calculator) { Spree::Calculator::Returns::DefaultRefundAmount.new }
  let(:order) { line_item.order }

  it_behaves_like 'a calculator with a description'

  subject { calculator.compute(return_item) }

  context "not an exchange" do
    context "no promotions or taxes" do
      it { is_expected.to eq line_item_price }
    end

    context "order adjustments" do
      let(:adjustment_amount) { -10.0 }

      before do
        order.adjustments << create(
          :adjustment,
          adjustable:  order,
          order:       order,
          amount:      adjustment_amount,
          eligible:    true,
          label:       'Adjustment',
          source_type: 'Spree::Order'
        )

        order.adjustments.first.update_attributes(amount: adjustment_amount)
      end

      it { is_expected.to eq line_item_price - (adjustment_amount.abs / line_item_quantity) }
    end

    context "shipping adjustments" do
      let(:adjustment_total) { -50.0 }

      before { order.shipments << Spree::Shipment.new(adjustment_total: adjustment_total) }

      it { is_expected.to eq line_item_price }
    end
  end

  context "an exchange" do
    let(:return_item) { build(:exchange_return_item) }

    it { is_expected.to eq 0.0 }
  end

  context "line item amount is zero" do
    let(:line_item_price) { 0 }
    it { is_expected.to eq 0.0 }
  end
end
