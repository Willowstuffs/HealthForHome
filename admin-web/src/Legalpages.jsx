import privacyPolicy from "./legal/privacy";
import termsUser from "./legal/termsUser";
import termsSpecialist from "./legal/termsSpecialist";
import locationPolicy from "./legal/location";
import "./styles/legal.css"
import { useParams } from "react-router-dom";

export default function LegalPage() {
  const { type } = useParams();

  const pages = {
    privacy: {
      content: privacyPolicy
    },
    "terms-user": {
      content: termsUser
    },
    "terms-specialist": {
      content: termsSpecialist
    },
    location: {
      content: locationPolicy
    }
  };

  const page = pages[type];

  if (!page) {
    return <div style={{ padding: 40 }}>404 – Dokument nie istnieje</div>;
  }

  return (
  <div className="legal-page-bg">
    <div className="legal-container">
      <h1>{page.title}</h1>

      <div
        className="legal-content"
        dangerouslySetInnerHTML={{ __html: page.content }}
      />
    </div>
  </div>
);
  
}