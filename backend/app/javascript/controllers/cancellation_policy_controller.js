import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["policy", "detail"]

  connect() {
    this.update()
  }

  update() {
    const selectedPolicy = this.policyTarget.value

    this.detailTargets.forEach((detail) => {
      const selected = detail.dataset.policyType === selectedPolicy

      detail.hidden = !selected
      detail.setAttribute("aria-hidden", String(!selected))
    })
  }
}
