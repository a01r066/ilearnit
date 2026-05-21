// Mobile nav toggle + smooth FAQ anchor scroll.
(() => {
  const toggle = document.querySelector('.nav-toggle');
  const links = document.querySelector('.nav-links');

  if (toggle && links) {
    toggle.addEventListener('click', () => {
      const open = links.classList.toggle('is-open');
      toggle.setAttribute('aria-expanded', String(open));
    });
    // Close menu after tapping a link.
    links.addEventListener('click', (e) => {
      if (e.target.matches('a')) links.classList.remove('is-open');
    });
  }

  // Highlight active section in the nav while scrolling.
  const sections = document.querySelectorAll('section[id]');
  if (sections.length) {
    const navLinks = document.querySelectorAll('.nav-links a[href^="#"]');
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue;
          const id = entry.target.id;
          navLinks.forEach((a) => {
            a.classList.toggle('is-active', a.getAttribute('href') === `#${id}`);
          });
        }
      },
      { rootMargin: '-50% 0px -45% 0px', threshold: 0 },
    );
    sections.forEach((s) => observer.observe(s));
  }

  // Set the current year in any [data-year] node.
  document.querySelectorAll('[data-year]').forEach((el) => {
    el.textContent = new Date().getFullYear();
  });
})();
