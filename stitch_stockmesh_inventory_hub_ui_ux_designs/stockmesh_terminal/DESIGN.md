---
name: StockMesh Terminal
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#3e4a3d'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#6e7b6c'
  outline-variant: '#bdcaba'
  surface-tint: '#006e2d'
  primary: '#006b2c'
  on-primary: '#ffffff'
  primary-container: '#00873a'
  on-primary-container: '#f7fff2'
  inverse-primary: '#62df7d'
  secondary: '#0051d5'
  on-secondary: '#ffffff'
  secondary-container: '#316bf3'
  on-secondary-container: '#fefcff'
  tertiary: '#712ae2'
  on-tertiary: '#ffffff'
  tertiary-container: '#8a4cfc'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#7ffc97'
  primary-fixed-dim: '#62df7d'
  on-primary-fixed: '#002109'
  on-primary-fixed-variant: '#005320'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#b4c5ff'
  on-secondary-fixed: '#00174b'
  on-secondary-fixed-variant: '#003ea8'
  tertiary-fixed: '#eaddff'
  tertiary-fixed-dim: '#d2bbff'
  on-tertiary-fixed: '#25005a'
  on-tertiary-fixed-variant: '#5a00c6'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 16px
  margin-tablet: 24px
  gutter: 16px
  touch-target-min: 48px
---

## Brand & Style

The design system is engineered for efficiency, reliability, and precision. It targets professional warehouse managers and retail operators who require a tool that feels institutional yet cutting-edge. The aesthetic is a refined evolution of **Material 3**, blending the systematic logic of **Corporate Modernism** with the high-fidelity finish of **Minimalism**.

The UI must evoke a sense of "quiet power"—it stays out of the way during high-speed scanning but provides deep, analytical clarity when needed. The "Offline-First" nature is communicated through a persistent, low-profile status bar and optimistic micro-interactions that signal data safety even without a network connection.

## Colors

The palette utilizes a "functional logic" where color is used exclusively to denote status or category, never for decoration. 

- **Primary (Emerald):** Represents growth, active inventory, and "Ready/Synced" states.
- **Info (Blue):** Used for navigation cues and technical metadata.
- **Warning/Critical:** Reserved for low-stock alerts and sync conflicts.
- **Analytics (Purple):** Distinguishes data-heavy views (trends, forecasts) from operational views.
- **Neutrals:** A sophisticated range of Slate grays that provide high-contrast legibility against the `#FFFFFF` surface containers and `#F8FAFC` background canvas.

## Typography

The typography system relies on **Inter** for its exceptional legibility at small scales and its neutral, systematic character. 

- **Display & Headlines:** Use a tighter letter-spacing and heavier weight to create a sense of hierarchy and authority.
- **Numerical Data:** For inventory counts, ensure the use of tabular figures (monospaced numbers) to maintain alignment in lists.
- **Labels:** Always uppercase with slight letter-spacing to distinguish metadata from actionable body text.

## Layout & Spacing

This design system uses a **Fluid Grid** model with an 8px base unit. Layouts are optimized for one-handed mobile use ("Thumb Zone" design).

- **Mobile:** 4-column layout with 16px margins. Primary actions are pinned to the bottom 30% of the screen.
- **Tablet:** 12-column layout with 24px margins. Utilizes a "List-Detail" view to maximize the large screen real estate.
- **Vertical Spacing:** Generous padding within cards (minimum 20px) to prevent visual clutter and ensure large, accessible touch targets for fast-paced environment scanning.

## Elevation & Depth

Hierarchy is established through **Tonal Layering** supplemented by **Ambient Shadows**.

1.  **Level 0 (Canvas):** The base background layer in `#F8FAFC`.
2.  **Level 1 (Cards):** Resting state for primary content. Uses a subtle `0px 1px 3px rgba(0,0,0,0.05)` shadow and a 1px border in a light neutral tint.
3.  **Level 2 (Active/Floating):** For Floating Action Buttons (FABs) and active sheets. Uses a more diffused shadow `0px 8px 20px rgba(0,0,0,0.08)` to suggest physical proximity to the user.

Avoid heavy blurs; maintain a "flat but layered" appearance similar to the Stripe dashboard.

## Shapes

The shape language is "Soft-Modern." 
- **Cards & Surfaces:** Use `rounded-lg` (16px) to evoke a friendly, professional feel reminiscent of modern hardware.
- **Input Fields & Buttons:** Use `rounded-md` (8px) to maintain structural integrity and clear boundaries.
- **Status Indicators:** Use full circles (pill-shaped) for "Synced" or "Offline" badges to distinguish them from actionable buttons.

## Components

### Buttons
- **Primary:** High-contrast Emerald Green background with White text. Minimum height 56px for mobile efficiency.
- **Secondary:** Ghost style with a 1px Slate-200 border.

### Cards
Large-format containers with 20px internal padding. Cards used for inventory items should include a "Sync Status" dot in the top-right corner (Emerald for synced, Orange for pending).

### Input Fields
Filled style with a bottom-only border or a very subtle 1px neutral outline. Focus state utilizes a 2px Primary (Emerald) border.

### Offline Indicators
A persistent "Connectivity Ribbon" at the top of the screen or within the Bottom Navigation Bar.
- **Offline:** Gray icon with "Local Mode" text.
- **Syncing:** Rotating Primary Green icon.
- **Synced:** Static Primary Green checkmark.

### Icons
Use **Material Symbols Rounded** exclusively. Maintain a consistent optical weight (200-300) to match the Inter typeface.