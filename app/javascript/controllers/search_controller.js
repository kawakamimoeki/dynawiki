import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button"];

  submit(event) {
    if (event.target.value === "") {
      return;
    }
    if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
      event.preventDefault();
      this.buttonTarget.click();
    }
  }
}
