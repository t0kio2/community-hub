class Tenant::StayManagement::InventoryBlocksController < Tenant::StayManagement::BaseController
  def index
    rooms = @stay_listing.stay_rooms
    room_blocks = StayRoomBlock.where(stay_room: rooms).includes(stay_room: :stay_room_type)
    beds = StayBed.where(stay_room: rooms)
    bed_blocks = StayBedBlock.where(stay_bed: beds).includes(stay_bed: { stay_room: :stay_room_type })

    @blocks = (room_blocks.to_a + bed_blocks.to_a).sort_by { |block| [block.starts_on, block.ends_on, block.id] }
  end
end
