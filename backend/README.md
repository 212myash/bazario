# Bazario Backend (Production-Ready Ecommerce API)

This backend is built with Node.js, Express.js, MongoDB (Mongoose), and JWT auth.
It is designed to be scalable, secure, and ready for real-world deployment.

## 1) Folder Structure

```text
backend/
  .env.example
  .gitignore
  package.json
  render.yaml
  postman/
    Bazario-Ecommerce.postman_collection.json
  src/
    app.js
    server.js
    config/
      env.js
      db.js
      cloudinary.js
    constants/
      roles.js
    controllers/
      admin.controller.js
      auth.controller.js
      cart.controller.js
      category.controller.js
      order.controller.js
      payment.controller.js
      product.controller.js
      review.controller.js
      upload.controller.js
      user.controller.js
      wishlist.controller.js
    middleware/
      auth.middleware.js
      error.middleware.js
      upload.middleware.js
    models/
      cart.model.js
      category.model.js
      order.model.js
      product.model.js
      review.model.js
      user.model.js
      wishlist.model.js
    routes/
      admin.routes.js
      auth.routes.js
      cart.routes.js
      category.routes.js
      index.js
      order.routes.js
      payment.routes.js
      product.routes.js
      review.routes.js
      upload.routes.js
      user.routes.js
      wishlist.routes.js
    scripts/
      seedAdmin.js
    services/
      payment.service.js
    utils/
      ApiError.js
      ApiResponse.js
      asyncHandler.js
      pagination.js
      slugify.js
      token.js
```

## 2) Backend Setup (Step-by-Step)

### Step 1: Install dependencies

```bash
cd backend
npm install
```

### Step 2: Add environment file

```bash
cp .env.example .env
```

Fill all required keys in `.env`.

### Step 3: Run development server

```bash
npm run dev
```

Health check:

```bash
GET http://localhost:5000/api/health
```

### Step 4: Seed admin user

```bash
npm run seed:admin -- admin@bazario.com Admin@12345
```

## 3) Core Features Implemented

- JWT Register/Login/Refresh/Logout
- Password hashing with bcrypt
- Role-based auth (`user`, `admin`)
- Product CRUD (admin), listing with pagination/filter/search
- Category management
- Persistent cart in DB
- Place order + order history + admin status updates
- Stripe payment intent (test mode)
- Razorpay order + signature verification (test mode)
- User profile + address management
- Cloudinary image upload
- Wishlist APIs
- Ratings and reviews
- Admin dashboard stats APIs
- Security middleware: helmet, rate-limit, mongo-sanitize, hpp

## 4) REST API Overview

Base URL: `/api`

- Auth:
  - `POST /auth/register`
  - `POST /auth/login`
  - `POST /auth/refresh-token`
  - `POST /auth/logout`
- Users:
  - `GET /users/me`
  - `PATCH /users/me`
  - `POST /users/me/addresses`
  - `PATCH /users/me/addresses/:addressId`
  - `DELETE /users/me/addresses/:addressId`
- Categories:
  - `GET /categories`
  - `POST /categories` (admin)
  - `PATCH /categories/:categoryId` (admin)
  - `DELETE /categories/:categoryId` (admin)
- Products:
  - `GET /products`
  - `GET /products/:slug`
  - `POST /products` (admin)
  - `PATCH /products/:productId` (admin)
  - `DELETE /products/:productId` (admin)
- Cart:
  - `GET /cart`
  - `POST /cart/items`
  - `PATCH /cart/items`
  - `DELETE /cart/items/:productId`
  - `DELETE /cart`
- Orders:
  - `POST /orders`
  - `GET /orders/my`
  - `GET /orders/my/:orderId`
  - `PATCH /orders/:orderId/status` (admin)
- Payments:
  - `POST /payments/stripe/intent`
  - `POST /payments/razorpay/order`
  - `POST /payments/razorpay/verify`
- Reviews:
  - `POST /reviews/:productId`
  - `DELETE /reviews/:productId`
- Wishlist:
  - `GET /wishlist`
  - `POST /wishlist`
  - `DELETE /wishlist/:productId`
- Upload:
  - `POST /upload/image` (admin)
- Admin:
  - `GET /admin/dashboard`
  - `GET /admin/orders`

## 5) MongoDB Atlas Setup

1. Create free cluster in MongoDB Atlas.
2. Create DB user and password.
3. Allow your IP (or `0.0.0.0/0` for testing only).
4. Copy connection string into `MONGODB_URI`.
5. Recommended indexes are already defined in models for:
   - email
   - product text search
   - category, brand, price
   - order status, payment status, createdAt
   - review compound unique (user + product)

## 6) Free Deployment Guide

### Backend on Render (Free)

1. Push project to GitHub.
2. In Render, create Web Service from repo.
3. Set Root Directory as `backend`.
4. Build command: `npm install`
5. Start command: `npm start`
6. Add all env variables from `.env.example`.
7. Use `render.yaml` for reproducible setup.

### Database on MongoDB Atlas (Free)

- Keep using your Atlas URI in Render env vars.

## 7) Postman Testing

- Import file: `backend/postman/Bazario-Ecommerce.postman_collection.json`
- Start from Auth requests.
- Save JWT token to `token` variable.
- Test protected routes (cart/order/profile/admin).

## 8) Security + Production Notes

- Use strong JWT secrets.
- Rotate secrets regularly.
- Restrict CORS to Flutter app origin.
- Validate request payloads before production launch.
- Add webhook signature verification for Stripe events if using webhook flows.
- Add centralized logging (Winston/Pino) and monitoring.

## 9) What to Build Next

- Flutter app with Riverpod + Dio + Clean Architecture
- API client + token interceptor
- Full UI screens (auth, home, product, cart, checkout, orders, profile, admin)
