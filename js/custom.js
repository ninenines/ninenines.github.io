var projects_nav = function() {
	var nav = document.querySelectorAll('.navbar .nav li a');
	var panels = document.querySelectorAll('.carousel-inner>div');

	Array.prototype.forEach.call(nav, function(el) {
		el.addEventListener('click', function(ev) {
			ev.preventDefault();

			Array.prototype.forEach.call(nav, function(el) {
				el.parentNode.classList.remove('active');
			});

			Array.prototype.forEach.call(panels, function(el) {
				el.classList.remove('active');
			});

			this.parentNode.classList.add('active');
			document.querySelector('.carousel-inner>div:nth-child('
				+ (1 + parseInt(this.dataset.panel, 10)) + ')')
				.classList.add('active');
		});
	});
};

var docs_nav = function() {
	var nav = document.querySelector('#docs-nav');
	if (nav === null) {
		return;
	}

	var docs = document.querySelectorAll('#docs h2');
	if (docs.length == 0) {
		nav.parentNode.removeChild(el);
	} else {
		var navul = document.createElement('ul');
		Array.prototype.forEach.call(docs, function(el) {
			navul.insertAdjacentHTML('beforeend',
				'<li><a href="#' + el.getAttribute('id') + '">'
					+ el.textContent + '</a></li>');
		});
		nav.insertAdjacentElement('afterend', navul);

		if (document.querySelector('#_rest_callbacks') !== null) {
			var restul = document.createElement('ul');
			var resth3s = document.querySelectorAll('#_rest_callbacks+div h3');
			Array.prototype.forEach.call(resth3s, function(el) {
				restul.insertAdjacentHTML('beforeend',
					'<li><a href="#' + el.getAttribute('id') + '">'
						+ el.textContent + '</a></li>');
			});
			document.querySelector('#docs-nav+ul a[href="#_rest_callbacks"]')
				.insertAdjacentElement('afterend', restul);
		}
	}
};

document.addEventListener('DOMContentLoaded', function() {
	projects_nav();
	docs_nav();
});
