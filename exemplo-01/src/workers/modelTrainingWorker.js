import 'https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@4.22.0/dist/tf.min.js';
import { workerEvents } from '../events/constants.js';
let _globalCtx = {};
// Normalize continous values (price, age) to 0-1 range
// Why? Keeps all feature balanced so no one dominates training
// Formula: (val - min) / (max - min)
// Example: price=129.99, minPrice=39.99, maxPrice=199.99 -> 0.56
const normalize = (value, min, max) => (value - min) / ((max - min) || 1)

function makeContext(catalog, users) {
    const ages = users.map(u => u.age)
    const prices = catalog.map(p => p.price)

    const minAge = Math.min(...ages)
    const maxAge = Math.max(...ages)

    const minPrice = Math.min(...prices)
    const maxPrice = Math.max(...prices)

    const colors = [...new Set(catalog.map(p => p.color))]
    const categories = [...new Set(catalog.map(p => p.category))]

    const colorsIndex = Object.entries(
        colors.map((color, index) => {
            return [color, index]
        }
    ))

    const categoriesIndex = Object.entries(
        categories.map((category, index) => {
            return [category, index]
        }
    ))

    // Computar a média de idade dos compradores por produto
    // ajuda a personalizar
    const midAge = (minAge + maxAge) / 2
    const ageSums = {}
    const ageCounts = {}

    users.forEach(user => {
        user.purchases.forEach(p => {
            ageSums[p.name] = (ageSums[p.name] || 0) + user.age
            ageCounts[p.name] = (ageCounts[p.name] || 0) + 1
        })
    })

    const productAvgAgeNorm = Object.fromEntries(
        catalog.map(product => {
            const avg = ageCounts[product.name] ? 
                ageSums[product.name] / ageCounts[product.name] :
                midAge

            return [product.name, normalize(avg, minAge, maxAge)]
        })
    )

    return {
        catalog,
        users,
        colorsIndex,
        categoriesIndex,
        minAge,
        maxAge,
        minPrice,
        maxPrice,
        numCategories: categories.length,
        numColors: colors.length,
        // price + age + cate + colors
        dimensions: 2 + categories.length + colors.length
    }
}
async function trainModel({ users }) {
    console.log('Training model with users:', users);
    postMessage({ type: workerEvents.progressUpdate, progress: { progress: 1 } });

    const catalog = await (await fetch('/data/products.json')).json()

    const context = makeContext(catalog, users)
    debugger
    postMessage({
        type: workerEvents.trainModel,
        epoch: 1,
        loss: 1,
        accuracy: 1
    })

    setTimeout(() => {
        postMessage({ type: workerEvents.progressUpdate, progress: { progress: 100} })
        postMessage({ type: workerEvents.trainingComplete })
    })
}
function recommend({ user }) {
    console.log('will recommend for user:', user);
}

const handlers = {
    [workerEvents.trainModel]: trainModel,
    [workerEvents.recommend]: recommend,
};

self.onmessage = e => {
    const { action, ...data } = e.data;
    if (handlers[action]) handlers[action](data);
};
