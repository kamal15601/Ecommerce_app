# Flask views for server-side rendered pages
from flask import render_template, redirect, url_for, request, flash, session
from .models import db, User, Product, Category, ProductImage, Review, CartItem, Wishlist, Order, OrderItem
from werkzeug.security import generate_password_hash, check_password_hash
from flask import Blueprint

views_bp = Blueprint('views', __name__)

@views_bp.route('/')
def home():
    products = Product.query.all()
    categories = Category.query.all()
    return render_template('home.html', products=products, categories=categories)

@views_bp.route('/product/<int:product_id>')
def product_detail(product_id):
    product = Product.query.get_or_404(product_id)
    reviews = Review.query.filter_by(product_id=product_id).all()
    images = ProductImage.query.filter_by(product_id=product_id).all()
    return render_template('product_detail.html', product=product, reviews=reviews, images=images)

@views_bp.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        username = request.form['username']
        email = request.form['email']
        password = request.form['password']
        if User.query.filter_by(email=email).first():
            flash('Email already exists')
            return redirect(url_for('views.signup'))
        user = User(username=username, email=email, password_hash=generate_password_hash(password))
        db.session.add(user)
        db.session.commit()
        flash('Signup successful! Please login.')
        return redirect(url_for('views.login'))
    return render_template('signup.html')

@views_bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        user = User.query.filter_by(email=email).first()
        if not user or not check_password_hash(user.password_hash, password):
            flash('Invalid credentials')
            return redirect(url_for('views.login'))
        session['user_id'] = user.id
        session['username'] = user.username
        session['is_admin'] = user.is_admin
        flash('Login successful!')
        return redirect(url_for('views.home'))
    return render_template('login.html')

@views_bp.route('/logout')
def logout():
    session.clear()
    flash('Logged out successfully!')
    return redirect(url_for('views.home'))

@views_bp.route('/cart')
def cart():
    if 'user_id' not in session:
        flash('Please login to view cart')
        return redirect(url_for('views.login'))
    cart_items = CartItem.query.filter_by(user_id=session['user_id']).all()
    return render_template('cart.html', cart_items=cart_items)

@views_bp.route('/wishlist')
def wishlist():
    if 'user_id' not in session:
        flash('Please login to view wishlist')
        return redirect(url_for('views.login'))
    wishlist_items = Wishlist.query.filter_by(user_id=session['user_id']).all()
    return render_template('wishlist.html', wishlist_items=wishlist_items)

@views_bp.route('/checkout')
def checkout():
    if 'user_id' not in session:
        flash('Please login to checkout')
        return redirect(url_for('views.login'))
    cart_items = CartItem.query.filter_by(user_id=session['user_id']).all()
    total = sum(item.product.price * item.quantity for item in cart_items)
    return render_template('checkout.html', cart_items=cart_items, total=total)

@views_bp.route('/admin')
def admin():
    if 'user_id' not in session or not session.get('is_admin'):
        flash('Admin access required')
        return redirect(url_for('views.login'))
    products = Product.query.all()
    categories = Category.query.all()
    orders = Order.query.all()
    return render_template('admin.html', products=products, categories=categories, orders=orders)

# ...existing code...
