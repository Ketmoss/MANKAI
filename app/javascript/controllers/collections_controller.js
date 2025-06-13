import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "select"]
  static values = {
    id: String
  }
  submit(event) {
    event.preventDefault()

    const form = event.currentTarget
    // console.log(form)
    const submit = form.querySelector(".collection-select")
    // console.log(submit.dataset)
    const collectionId = submit.dataset.idCollectionsValue
    // console.log(collectionId)

    if (!collectionId) {
      console.log("Veuillez sélectionner une collection")
      return
    }


    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    form.appendChild(csrfInput)

    const baseUrl = `/user_collections/${collectionId}/owned_mangas`
    form.action = baseUrl

    form.submit()
  }
}
