/* Waraq Install Guide — vanilla JS, no dependencies. */
(function () {
  "use strict";

  /* ---- Tab switcher (DMG / PKG) with sliding indicator ---- */
  var tabs = document.querySelectorAll(".tab-button");
  var indicator = document.querySelector(".tab-indicator");

  function moveIndicator(btn) {
    if (!indicator || !btn) return;
    indicator.style.width = btn.offsetWidth + "px";
    indicator.style.transform = "translateX(" + (btn.offsetLeft - 5) + "px)";
  }

  function activateTab(name) {
    tabs.forEach(function (b) {
      var on = b.dataset.tab === name;
      b.classList.toggle("active", on);
      b.setAttribute("aria-selected", on ? "true" : "false");
      if (on) moveIndicator(b);
    });
    document.querySelectorAll(".tab-content").forEach(function (c) {
      c.classList.toggle("active", c.dataset.content === name);
    });
  }

  tabs.forEach(function (b) {
    b.addEventListener("click", function () { activateTab(b.dataset.tab); });
  });
  // initial indicator position (after layout)
  var firstActive = document.querySelector(".tab-button.active");
  if (firstActive) {
    requestAnimationFrame(function () { moveIndicator(firstActive); });
  }
  window.addEventListener("resize", function () {
    moveIndicator(document.querySelector(".tab-button.active"));
  });

  /* ---- Reveal sections + screenshots on scroll ---- */
  if ("IntersectionObserver" in window) {
    var revealObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) {
          e.target.classList.add("in-view");
          revealObserver.unobserve(e.target);
        }
      });
    }, { threshold: 0.12, rootMargin: "0px 0px -8% 0px" });
    document.querySelectorAll(".reveal").forEach(function (el) { revealObserver.observe(el); });
  } else {
    document.querySelectorAll(".reveal").forEach(function (el) { el.classList.add("in-view"); });
  }

  /* ---- Sticky progress indicator ---- */
  var progressNav = document.querySelector(".progress-nav");
  var dots = document.querySelectorAll(".progress-dot");
  var hero = document.querySelector(".hero");
  var sections = Array.prototype.map.call(dots, function (d) {
    return document.getElementById(d.dataset.section);
  });

  if ("IntersectionObserver" in window && progressNav) {
    var sectionObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) {
          dots.forEach(function (d) {
            d.classList.toggle("active", d.dataset.section === e.target.id);
          });
        }
      });
    }, { threshold: 0.5 });
    sections.forEach(function (s) { if (s) sectionObserver.observe(s); });
  }

  /* ---- Show progress nav + back-to-top after hero ---- */
  var backToTop = document.querySelector(".back-to-top");
  function onScroll() {
    var past = window.scrollY > (hero ? hero.offsetHeight - 120 : 400);
    if (progressNav) progressNav.classList.toggle("visible", past);
    if (backToTop) backToTop.classList.toggle("visible", past);
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  if (backToTop) {
    backToTop.addEventListener("click", function (ev) {
      ev.preventDefault();
      window.scrollTo({ top: 0, behavior: "smooth" });
    });
  }

  /* ---- Download button click feedback (does NOT block the download) ---- */
  var dl = document.getElementById("downloadBtn");
  if (dl) {
    dl.addEventListener("click", function (ev) {
      var rect = dl.getBoundingClientRect();
      dl.style.setProperty("--bx", (ev.clientX - rect.left) + "px");
      dl.style.setProperty("--by", (ev.clientY - rect.top) + "px");
      dl.classList.remove("clicked");
      // reflow to restart the burst animation
      void dl.offsetWidth;
      dl.classList.add("clicked");
      // the <a download> handles the actual file download natively
    });
  }
})();
