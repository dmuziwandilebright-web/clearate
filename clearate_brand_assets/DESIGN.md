---
name: Financial Truth System
colors:
  surface: '#f7f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#45464d'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#76777d'
  outline-variant: '#c6c6cd'
  surface-tint: '#565e74'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#131b2e'
  on-primary-container: '#7c839b'
  inverse-primary: '#bec6e0'
  secondary: '#505f76'
  on-secondary: '#ffffff'
  secondary-container: '#d0e1fb'
  on-secondary-container: '#54647a'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#271901'
  on-tertiary-container: '#98805d'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2fd'
  primary-fixed-dim: '#bec6e0'
  on-primary-fixed: '#131b2e'
  on-primary-fixed-variant: '#3f465c'
  secondary-fixed: '#d3e4fe'
  secondary-fixed-dim: '#b7c8e1'
  on-secondary-fixed: '#0b1c30'
  on-secondary-fixed-variant: '#38485d'
  tertiary-fixed: '#fcdeb5'
  tertiary-fixed-dim: '#dec29a'
  on-tertiary-fixed: '#271901'
  on-tertiary-fixed-variant: '#574425'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
typography:
  display-lg:
    fontFamily: Public Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Public Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Public Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Public Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Public Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Public Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Public Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  stat-lg:
    fontFamily: Public Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  touch-target: 48px
  container-margin: 16px
---

## Brand & Style

The design system is anchored in the concept of "Financial Truth." It aims to empower users with clarity and confidence in an often volatile economic environment. The aesthetic is **Corporate / Modern** with a strong emphasis on **Accessibility**. 

The UI prioritizes utility over decoration, using ample whitespace and a structured grid to make complex currency data digestible. The emotional response should be one of immediate relief and trust—a reliable tool that provides objective facts without visual clutter. By combining a "light-weight" data feel with authoritative navy tones, the design system bridges the gap between a high-end fintech app and a public service utility.

## Colors

This design system utilizes a high-contrast palette to ensure legibility for all users. 
- **Primary (Deep Navy):** Used for headers, primary actions, and authoritative text to instill a sense of institutional trust.
- **Neutrals:** A light-gray background (#F8FAFC) is used to keep the interface feeling "light" and reduce perceived data usage, while Slate-600 is used for secondary metadata.
- **Semantic Palette:** These are the most critical colors. They are used exclusively for status indicators:
    - **Vibrant Green:** Indicates "FAIR" rates.
    - **Bright Red:** Indicates "OVERCHARGED" or "CRITICAL" discrepancies.
    - **Amber:** Indicates "UNDERVALUED" or "CAUTION" states.

## Typography

The design system uses **Public Sans** across all levels due to its exceptional readability and institutional character. Typography is intentionally oversized to accommodate users with varying vision needs.

- **Display & Stats:** Large, bold weights are used for currency numbers to make them the focal point of every screen.
- **Semantic Labels:** Small caps with increased letter spacing are used for "FAIR" or "OVERCHARGED" tags to ensure they are distinct from numerical data.
- **Hierarchy:** Use `body-lg` as the default reading size for most text to ensure high accessibility on mobile devices.

## Layout & Spacing

The layout follows a **Fixed Grid** model for mobile devices, utilizing a 4-column system with a 16px outer margin. 

- **Vertical Rhythm:** A strict 8px base unit ensures consistent scaling. Use `lg` (24px) spacing between distinct content cards and `sm` (12px) for elements within a card.
- **Touch Targets:** All interactive elements (buttons, toggles, inputs) must maintain a minimum height of `48px` to ensure ease of use for older populations or users on the move.
- **Data Density:** Content should be "airy." Avoid cramming multiple data points into a single row; instead, use vertical stacking with clear labels.

## Elevation & Depth

This design system uses **Tonal Layers** and **Low-Contrast Outlines** rather than heavy shadows to keep the UI feeling "light" and performant.

- **Level 0 (Background):** Solid `#F8FAFC`.
- **Level 1 (Cards):** White surfaces with a 1px border of `#E2E8F0`. This creates a clean "sheet" look.
- **Level 2 (Active/Floating):** Use a very soft, diffused shadow (10% opacity Deep Navy, 8px blur) only for primary action buttons or "Alert" modals that require immediate attention.
- **Depth via Color:** Use the Primary Navy color to create a "Header" block that sits behind card elements, creating a natural layering effect without complex styling.

## Shapes

The design system uses a **Rounded** (0.5rem) shape language. This strikes a balance between the "friendly" nature of modern apps and the "structured" nature of financial institutions.

- **Standard Elements:** Buttons, Input fields, and Cards use the base `rounded` (8px) setting.
- **Status Pills:** Tags indicating "FAIR" or "OVERCHARGED" should use `rounded-xl` (24px) to create a distinct "pill" shape that separates them from the structural rectangular cards.
- **Consistency:** Avoid mixing sharp corners with rounded ones; all interactive containers must adhere to the 8px radius.

## Components

### Buttons
Primary buttons use the Deep Navy background with white text. They are full-width on mobile to maximize the hit area. Secondary buttons use a simple 1px outline.

### Status Indicators (Chips)
These are the most prominent components. They should use a light tinted background of the semantic color (e.g., 10% opacity green) with high-contrast bold text of the same color. 

### Cards
Cards are the primary container for rate information. Each card should have a clear title, a primary "stat" (the rate), and a footer area for the "Last Updated" timestamp.

### Input Fields
Inputs must have a permanent visible label (no floating labels that disappear). Use a large font size (18px) for numeric entry to prevent typing errors.

### Lists
Lists of currencies should use high horizontal padding (16px) and a subtle separator line. Each list item should have a chevron icon to indicate it is tappable.

### Alert Banners
When a rate is detected as an "Overcharge," a full-width banner at the top of the screen in Bright Red should appear, using the `headline-md` typography level for the warning message.