const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

function calculateTax(subtotal) {
  // VAT is a flat 20%
  return subtotal * 0.2;
}

function calculateShipping(subtotal, itemsCount) {
  // Shipping is $1 per item or free over $100
  if (subtotal > 100) {
    return 0;
  }

  return itemsCount;
}

exports.onCartItem = functions.firestore.document('/carts/{userId}/items/{itemId}').onWrite(async (change, ctx) => {
  // When a new cart item is added/deleted/update we recalculate tax and shipping
  const cartRef = admin.firestore().collection('carts').doc(ctx.params['userId']);
  const cartItemsRef = cartRef.collection('items');

  const cartItemsSnap = await cartItemsRef.get();
  const cartItems = cartItemsSnap.docs.map(d => d.data());

  // Calculate how many items are in the cart
  const itemsCount = cartItems.length;

  // Calculate the cart subtotal
  const subtotal = cartItems.reduce((acc, doc) => {
    return acc + doc.price;
  }, 0);

  // Update the shipping/tax info in the cart
  await cartRef.update({
    shipping: calculateShipping(subtotal, itemsCount),
    tax: calculateTax(subtotal)
  });
});
