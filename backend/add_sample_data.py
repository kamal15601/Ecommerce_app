# Script to add sample data to the database
from app import create_app, db
from app.models import User, Category, Product, ProductImage
from werkzeug.security import generate_password_hash

def add_sample_data():
    app = create_app()
    with app.app_context():
        # Create tables
        db.create_all()
        
        # Add sample categories
        if not Category.query.first():
            categories = [
                Category(name='Electronics'),
                Category(name='Clothing'),
                Category(name='Books'),
                Category(name='Home & Garden')
            ]
            for category in categories:
                db.session.add(category)
            db.session.commit()
            print("Sample categories added!")
        
        # Add sample products
        if not Product.query.first():
            electronics = Category.query.filter_by(name='Electronics').first()
            clothing = Category.query.filter_by(name='Clothing').first()
            
            products = [
                Product(name='Smartphone', description='Latest Android smartphone with excellent camera', 
                       price=599.99, brand='TechBrand', rating=4.5, category_id=electronics.id),
                Product(name='Laptop', description='High-performance laptop for work and gaming', 
                       price=1299.99, brand='CompuBrand', rating=4.7, category_id=electronics.id),
                Product(name='T-Shirt', description='Comfortable cotton t-shirt in various colors', 
                       price=19.99, brand='FashionBrand', rating=4.2, category_id=clothing.id),
                Product(name='Jeans', description='Classic denim jeans with perfect fit', 
                       price=79.99, brand='DenimBrand', rating=4.4, category_id=clothing.id)
            ]
            for product in products:
                db.session.add(product)
            db.session.commit()
            print("Sample products added!")
        
        # Add admin user
        if not User.query.filter_by(email='admin@example.com').first():
            admin = User(
                username='admin',
                email='admin@example.com',
                password_hash=generate_password_hash('admin123'),
                is_admin=True
            )
            db.session.add(admin)
            db.session.commit()
            print("Admin user added! Email: admin@example.com, Password: admin123")

if __name__ == '__main__':
    add_sample_data()
