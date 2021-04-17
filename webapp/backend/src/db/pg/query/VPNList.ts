import {sql} from 'slonik';

import Query from '../Query';

class VPNList extends Query {
  timestamp: Date;
  constructor(timestamp: Date) {
    super();
    this.timestamp = timestamp;
  }

  raw() {
    const timestampUnix = Math.round(this.timestamp.getTime() / 1000);
    return sql`
      SELECT community
      FROM (SELECT DISTINCT(JSONB_ARRAY_ELEMENTS_TEXT("comms")) as community
        FROM dump
        WHERE timestamp <= ${timestampUnix}
        AND timestamp > ${timestampUnix - this.timeBetweenDumps}
      ) AS t
      WHERE community LIKE ${'64497:%'}
    `;
  }

  async execute(): Promise<string[]> {
    const rows = (await this.executeQuery()) as {community: string}[];

    const distinctVpn = rows.map(x => x.community);
    return distinctVpn;
  }
}

export default VPNList;
