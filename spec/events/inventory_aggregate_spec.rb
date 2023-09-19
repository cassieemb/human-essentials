RSpec.describe InventoryAggregate do
  let(:organization) { FactoryBot.create(:organization) }
  let(:storage_location1) { FactoryBot.create(:storage_location, organization: organization)}
  let(:storage_location2) { FactoryBot.create(:storage_location, organization: organization)}
  let(:item1) { FactoryBot.create(:item, organization: organization)}
  let(:item2) { FactoryBot.create(:item, organization: organization)}
  let(:item3) { FactoryBot.create(:item, organization: organization)}

  describe 'individual events' do
    let(:inventory) do
      EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 30),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            })
        })
    end

    it 'should process a donation event' do
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 50, item: item1)
      donation.line_items << build(:line_item, quantity: 30, item: item2)
      DonationEvent.publish(donation)

      # 30 + 50 = 80, 10 + 30 = 40
      InventoryAggregate.handle(DonationEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 80),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 40),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            })
        }))
    end

    it 'should process a distribution event' do
      dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
      dist.line_items << build(:line_item, quantity: 20, item: item1)
      dist.line_items << build(:line_item, quantity: 5, item: item2)
      DistributionEvent.publish(dist)

      # 30 - 20 = 10, 10 - 5 = 5
      InventoryAggregate.handle(DistributionEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            })
        }))
    end

    it 'should process an adjustment event' do
      adjustment = FactoryBot.create(:adjustment, organization: organization, storage_location: storage_location1)
      adjustment.line_items << build(:line_item, quantity: 20, item: item1)
      adjustment.line_items << build(:line_item, quantity: -5, item: item2)
      AdjustmentEvent.publish(adjustment)

      # 30 + 20 = 50, 10 - 5 = 5
      InventoryAggregate.handle(AdjustmentEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 50),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            })
        }))

    end

    it 'should process a purchase event' do
      purchase = FactoryBot.create(:purchase, organization: organization, storage_location: storage_location1)
      purchase.line_items << build(:line_item, quantity: 50, item: item1)
      purchase.line_items << build(:line_item, quantity: 30, item: item2)
      PurchaseEvent.publish(purchase)

      # 30 + 50 = 80, 10 + 30 = 40
      InventoryAggregate.handle(PurchaseEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 80),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 40),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            })
        }))

    end

    it 'should process a distribution destroyed event' do
      dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
      dist.line_items << build(:line_item, quantity: 50, item: item1)
      dist.line_items << build(:line_item, quantity: 30, item: item2)
      DistributionDestroyEvent.publish(dist)

      # 30 + 50 = 80, 10 + 30 = 40
      InventoryAggregate.handle(DistributionDestroyEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 80),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 40),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            })
        }))

    end

    it 'should process a transfer event' do
      transfer = FactoryBot.create(:transfer, organization: organization, from: storage_location1, to: storage_location2)
      transfer.line_items << build(:line_item, quantity: 20, item: item1)
      transfer.line_items << build(:line_item, quantity: 5, item: item2)
      TransferEvent.publish(transfer)

      # 30 - 20 = 10, 10 - 5 = 5
      # 0 + 20 = 20, 10 + 5 = 15
      InventoryAggregate.handle(TransferEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 20),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 15),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            })
        }))

    end

    it 'should process an audit event' do
      audit = FactoryBot.create(:audit, organization: organization, storage_location: storage_location1)
      audit.line_items << build(:line_item, quantity: 20, item: item1)
      audit.line_items << build(:line_item, quantity: 10, item: item3)
      AuditEvent.publish(audit)

      InventoryAggregate.handle(AuditEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 20),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 10)
            }),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            })
        }))
    end

  end

  it 'should process multiple events' do
    donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
    donation.line_items << build(:line_item, quantity: 50, item: item1)
    donation.line_items << build(:line_item, quantity: 30, item: item2)
    DonationEvent.publish(donation)

    donation2 = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
    donation2.line_items << build(:line_item, quantity: 30, item: item1)
    DonationEvent.publish(donation2)

    donation3 = FactoryBot.create(:donation, organization: organization, storage_location: storage_location2)
    donation3.line_items << build(:line_item, quantity: 50, item: item2)
    DonationEvent.publish(donation3)

    # correction event
    donation3.line_items = [build(:line_item, quantity: 40, item: item2)]
    DonationEvent.publish(donation3)

    dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
    dist.line_items << build(:line_item, quantity: 10, item: item1)
    DistributionEvent.publish(dist)

    dist2 = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location2)
    dist2.line_items << build(:line_item, quantity: 15, item: item2)
    DistributionEvent.publish(dist2)

    inventory = described_class.inventory_for(organization.id)
    expect(inventory).to eq(EventTypes::Inventory.new(
      organization_id: organization.id,
      storage_locations: {
        storage_location1.id => EventTypes::EventStorageLocation.new(
          id: storage_location1.id,
          items: {
            item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 70),
            item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 30)
          }),
        storage_location2.id => EventTypes::EventStorageLocation.new(
          id: storage_location2.id,
          items: {
            item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 25)
          }
        )
      }
    ))

  end
end
