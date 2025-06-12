// Dans votre JavaScript
document.addEventListener('turbo:load', function() {
  const forms = document.querySelectorAll('.add-to-collection-form');

  forms.forEach(form => {
    form.addEventListener('submit', function(e) {
      e.preventDefault();

      const select = form.querySelector('.collection-select');
      const collectionId = select.value;

      if (!collectionId) {
        alert('Veuillez sélectionner une collection');
        return;
      }

      // Ajouter le CSRF token
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
      const csrfInput = document.createElement('input');
      csrfInput.type = 'hidden';
      csrfInput.name = 'authenticity_token';
      csrfInput.value = csrfToken;
      form.appendChild(csrfInput);

      // Mettre à jour l'URL
      const baseUrl = `/user_collections/${collectionId}/owned_mangas`;
      form.action = baseUrl;

      // Soumettre
      form.submit();
    });
  });
});
