import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "model", "temperature", "promptTemplate"]

  connect() {
    // Check initial state
    this.toggleInputs()
  }

  toggleInputs() {
    const isBlank = !this.templateTarget.value

    // Get parent control-group divs to hide/show entire sections
    const modelGroup = this.modelTarget.closest('.control-group')
    const temperatureGroup = this.temperatureTarget.closest('.control-group')
    const promptTemplateGroup = this.promptTemplateTarget.closest('.control-group')

    if (isBlank) {
      modelGroup.style.display = 'block'
      temperatureGroup.style.display = 'block'
      promptTemplateGroup.style.display = 'block'
    } else {
      modelGroup.style.display = 'none'
      temperatureGroup.style.display = 'none'
      promptTemplateGroup.style.display = 'none'
    }
  }
}
