# API routes for e-commerce app
from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from .models import db, User, Product, Category, ProductImage, Review, CartItem, Wishlist, Order, OrderItem
from werkzeug.security import generate_password_hash, check_password_hash

api_bp = Blueprint('api', __name__)

@api_bp.route('/auth/signup', methods=['POST'])
def signup():
    data = request.json
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'msg': 'Email already exists'}), 400
    user = User(
        username=data['username'],
        email=data['email'],
        password_hash=generate_password_hash(data['password'])
    )
    db.session.add(user)
    db.session.commit()
    return jsonify({'msg': 'Signup successful'}), 201

@api_bp.route('/auth/login', methods=['POST'])
def login():
    data = request.json
    user = User.query.filter_by(email=data['email']).first()
    if not user or not check_password_hash(user.password_hash, data['password']):
        return jsonify({'msg': 'Invalid credentials'}), 401
    access_token = create_access_token(identity=user.id)
    return jsonify({'access_token': access_token, 'user': {'id': user.id, 'username': user.username, 'is_admin': user.is_admin}})

@api_bp.route('/auth/logout', methods=['POST'])
@jwt_required()
def logout():
    return jsonify({'msg': 'Logout successful'})

# ...additional routes for products, categories, cart, wishlist, orders, admin, etc. will be added here...
