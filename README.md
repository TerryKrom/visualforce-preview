# 📅 Custom Timeline + Visualforce Preview (LWC)

**Custom Timeline** is a **Lightning Web Component** that displays an interactive timeline of activities grouped by month.  
It supports email previews (HTML or plain text) and works seamlessly inside **Lightning Pages** or **Visualforce** via wrappers or Lightning Out.

---

## ✨ Features

- 📂 **Monthly grouping** with collapsible accordion sections  
- ⏰ Special **"Upcoming & Overdue"** section  
- 📧 Expandable email previews with sender, recipient, and body (HTML or text)  
- 🔽 Interactive icons to expand/collapse emails and sections  
- ⚙️ Per-item action menu with **Edit** and **Delete** options  
- 📤 Global **"Send Email"** button displayed above timeline sections  
- 🗑️ Confirmation modal for delete actions  

---

## 🚀 Installation & Usage

### 1. Add the component
Place the component in a **Lightning Page** or embed it in a **Visualforce Page** using `lightning:container` or **Lightning Out**:

```html
<c-custom-timeline></c-custom-timeline>
