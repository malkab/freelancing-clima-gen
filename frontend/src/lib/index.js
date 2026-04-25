import DOMPurify from "dompurify";
import { marked } from "marked";

const sectionList = document.getElementById("left-nav-sections");
const mainContent = document.getElementById("main-content");

init();

async function init() {
    try {
        const response = await fetch("/content/main_content.md", { cache: "no-store" });

        if (!response.ok) {
            throw new Error(`Failed to load markdown: ${response.status}`);
        }

        const markdown = await response.text();
        mainContent.innerHTML = markdownToHtml(markdown);

        renderSectionLinks();
    } catch {
        mainContent.innerHTML = "<p>No se pudo cargar el contenido.</p>";
    }
}

function renderSectionLinks() {
    const headings = Array.from(document.querySelectorAll("div#main-content h1"));
    sectionList.innerHTML = "";

    headings.forEach((heading, index) => {
        const slug = heading.textContent
            .trim()
            .toLowerCase()
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "")
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/(^-|-$)/g, "");

        const id = slug.length > 0 ? slug : `section-${index + 1}`;
        heading.id = `${id}-${index + 1}`;

        const item = document.createElement("div");
        item.className = "section-link";
        const link = document.createElement("a");
        link.href = `#${heading.id}`;
        link.textContent = heading.textContent;
        item.appendChild(link);
        sectionList.appendChild(item);
    });
}

function markdownToHtml(markdown) {
    const renderedHtml = marked.parse(markdown, {
        gfm: true,
        breaks: true,
    });

    return DOMPurify.sanitize(renderedHtml, {
        USE_PROFILES: { html: true },
    });
}
