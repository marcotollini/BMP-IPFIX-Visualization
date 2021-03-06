import {RouterContext} from '@koa/router';
import {Next} from 'koa';
import {isString, partialRight} from 'lodash';

import Database from '../db/getDatabase';
import Router = require('@koa/router');
const router = new Router();

async function bmp_process(ctx: RouterContext, constructor: Function) {
  const reqBody = ctx.request.body;
  if (
    !reqBody.data ||
    !isString(reqBody.data.vpn) ||
    !isString(reqBody.data.timestamp)
  ) {
    ctx.throw('Missing vpn or timestamp', 500);
  }

  const vpn = reqBody.data.vpn;
  const timestamp = new Date(reqBody.data.timestamp);
  const filters = reqBody.data.filters;

  const query = constructor(timestamp, vpn, filters);

  ctx.req.on('close', query.cancel.bind(query));

  const result = await query.execute();

  ctx.req.removeListener('close', query.cancel);

  return result;
}

router.post('/api/bmp/state', async (ctx: RouterContext) => {
  ctx.body = await bmp_process(ctx, Database.BMPState);
});

router.get('/api/bmp/peerup', async (ctx: RouterContext) => {
  const reqQuery = ctx.request.query;
  if (!isString(reqQuery.timestamp)) {
    ctx.throw('Missing timestamp', 500);
  }

  const timestamp = new Date(reqQuery.timestamp);

  const query = Database.PeerUpState(timestamp);

  ctx.req.on('close', query.cancel.bind(query));

  const result = await query.execute();

  ctx.req.removeListener('close', query.cancel);

  ctx.body = result;
});

router.post('/api/bmp/filter/fields/list', async (ctx: RouterContext) => {
  ctx.body = await bmp_process(ctx, Database.FilterFieldsList);
});

router.post('/api/bmp/filter/fields/values', async (ctx: RouterContext) => {
  ctx.body = await bmp_process(ctx, Database.FilterFieldsValues);
});

router.post(
  '/api/bmp/filter/field/values/:fieldName',
  async (ctx: RouterContext) => {
    const fn = partialRight(Database.FilterFieldValues, ctx.params.fieldName);
    ctx.body = await bmp_process(ctx, fn);
  }
);

router.post('/api/bmp/count', async (ctx: RouterContext) => {
  const reqBody = ctx.request.body;
  const approximation =
    reqBody.data && reqBody.data.approximation === false ? false : true;
  const fn = partialRight(Database.CountEvents, approximation);
  ctx.body = await bmp_process(ctx, fn);
});

router.post(
  '/api/bmp/visualization/vpn/topology',
  async (ctx: RouterContext) => {
    ctx.body = await bmp_process(ctx, Database.VisualizationVPNTopology);
  }
);

router.post(
  '/api/bmp/visualization/vpn/routing-topology',
  async (ctx: RouterContext) => {
    ctx.body = await bmp_process(ctx, Database.VisualizationVPNRoutingTopology);
  }
);

router.post(
  '/api/bmp/visualization/peering/topology',
  async (ctx: RouterContext) => {
    ctx.body = await bmp_process(ctx, Database.VisualizationPeeringTopology);
  }
);

router.post('/api/bmp/visualization/list', async (ctx: RouterContext) => {
  const reqBody = ctx.request.body;
  const show = reqBody.data.show;

  if (!Array.isArray(show) || show.length === 0) {
    ctx.throw('Show columns empty');
  }

  const fn = partialRight(Database.VisualizationList, show);

  ctx.body = await bmp_process(ctx, fn);
});

export default router;
