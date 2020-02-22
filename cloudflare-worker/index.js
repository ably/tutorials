/* eslint-disable no-restricted-globals */
import Router from './router'
import reactorHook from './src/handler'
/**
 * Example of how router can be used in an application
 *  */
addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request))
})


async function handleRequest(request) {
    const r = new Router()
    r.post('/ably', reactorHook)

    const resp = await r.route(request)
    return resp
}
