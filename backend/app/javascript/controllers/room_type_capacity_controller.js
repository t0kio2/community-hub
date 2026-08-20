import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["roomKind", "capacity"]
  static values = { sharedRoom: String }

  connect() {
    this.update()
  }

  update() {
    const sharedRoomSelected = this.roomKindTarget.value === this.sharedRoomValue

    if (sharedRoomSelected) this.capacityTarget.value = "1"
    this.capacityTarget.readOnly = sharedRoomSelected
  }
}
