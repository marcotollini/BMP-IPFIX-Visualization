<template>
  <div id="cytoscape"></div>
</template>

<script lang="ts">
import {defineComponent} from 'vue';
import cytoscape, {EdgeSingular, NodeSingular} from 'cytoscape';

import {
  CytoGraph,
  CytoGraphDefaults,
  CytoEdgeDefaults,
  CytoNodeDefaults,
} from '@/types';
import {cloneDeep, defaults, partition} from 'lodash';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const colors = require('../colors.json');
// eslint-disable-next-line @typescript-eslint/no-var-requires
const graphDefaults = require('../graph-defaults.json');

function diff(nw: string[], old: string[]) {
  const newSet = new Set(nw);
  const oldSet = new Set(old);

  const add = nw.filter(x => !oldSet.has(x));
  const [del, update] = partition(old, x => !newSet.has(x));
  return [add, del, update];
}

function colorMap(color: string, type: 'node' | 'edge') {
  const typeMapping = type === 'node' ? colors.node : colors.edge;
  const typeColor = typeMapping[color] || color;
  const colorHex = colors.colors[typeColor] || colors;
  return colorHex;
}

function edgeToCytoscape(edge: CytoEdgeDefaults) {
  return {
    id: edge.id,
    source: edge.src,
    target: edge.dst,
    width: edge.width,
    color: edge.color,
  };
}

export default defineComponent({
  name: 'VPNTopology',
  props: {
    graph: {
      default: {nodes: {}, edges: {}} as CytoGraph,
      type: Object,
    },
  },
  data() {
    return {
      cytoGraph: {nodes: {}, edges: {}} as CytoGraphDefaults,
      cy: {} as cytoscape.Core,
    };
  },
  watch: {
    graph() {
      this.draw();
    },
  },
  methods: {
    draw() {
      if (this.cy === undefined) return;
      const cy = this.cy;
      const copyGraph = cloneDeep(this.graph) as CytoGraph;

      const [addNodes, deleteNodes, updateNodes] = diff(
        Object.keys(copyGraph.nodes),
        Object.keys(this.cytoGraph.nodes)
      );

      const [addEdges, deleteEdges, updateEdges] = diff(
        Object.keys(copyGraph.edges),
        Object.keys(this.cytoGraph.edges)
      );

      /* assign default to nodes and edges */
      addNodes.forEach(x => {
        copyGraph.nodes[x] = defaults(copyGraph.nodes[x], graphDefaults.node);
      });

      addEdges.forEach(x => {
        copyGraph.edges[x] = defaults(copyGraph.edges[x], graphDefaults.edge);
      });
      /* end assign default to nodes and edges */

      const copyGraphDefaults = copyGraph as CytoGraphDefaults;

      /* string to colors */
      [...addNodes, ...updateNodes].forEach(x => {
        const node = copyGraphDefaults.nodes[x];
        if (node && node.color) node.color = colorMap(node.color, 'node');
      });

      [...addEdges, ...updateEdges].forEach(x => {
        const edge = copyGraphDefaults.edges[x];
        if (edge && edge.color) edge.color = colorMap(edge.color, 'edge');
      });
      /* end string to colors */

      /* visibility set for nodes */
      addNodes.forEach(x => {
        const node = copyGraphDefaults.nodes[x];
        if (node.children)
          node.children.forEach(child => {
            const childNode = copyGraphDefaults.nodes[child];
            childNode.visible = false;
          });
      });
      /* end visibility set for nodes */

      /* update */
      updateNodes.forEach(x => {
        copyGraphDefaults.nodes[x] = {
          ...this.cytoGraph.nodes[x],
          ...copyGraphDefaults.nodes[x],
        };
      });

      updateEdges.forEach(x => {
        copyGraphDefaults.edges[x] = {
          ...this.cytoGraph.edges[x],
          ...copyGraphDefaults.edges[x],
        };
      });
      copyGraphDefaults.selected = this.cytoGraph.selected;
      this.cytoGraph = copyGraphDefaults;
      /* end update */

      /* visibility for edges */
      /**
       * needs to be after update as on on the updated nodes we do not apply the defauls
       * and so visibility might not be set yet. After update it is guaranteed
       */
      [...addEdges, ...updateEdges].forEach(x => {
        const edge = copyGraphDefaults.edges[x];
        edge.visible =
          copyGraphDefaults.nodes[edge.src].visible &&
          copyGraphDefaults.nodes[edge.dst].visible;
      });
      /* end visibility for edges */

      cy.startBatch();

      /* delete */
      deleteNodes.forEach(x => {
        cy.remove(cy.$id(x));
      });
      deleteEdges.forEach(x => {
        cy.remove(cy.$id(x));
      });
      /* end delete */

      /* add */
      cy.add(
        addNodes.map(x => {
          const node = copyGraphDefaults.nodes[x];
          return {
            group: 'nodes',
            data: node,
            classes: node.visible ? '' : 'hidden',
          };
        })
      );

      cy.add(
        addEdges.map(x => {
          const edge = copyGraphDefaults.edges[x];
          return {
            group: 'edges',
            data: edgeToCytoscape(edge),
            classes: edge.visible ? '' : 'hidden',
          };
        })
      );
      /* end add */

      /* update */
      updateNodes.map(x => {
        const update = copyGraphDefaults.nodes[x];
        const node = cy.$id(x);
        node.data(update);
        if (update.visible && node.hasClass('hidden')) {
          node.removeClass('hidden');
        } else if (!update.visible && !node.hasClass('hidden')) {
          node.addClass('hidden');
        }
      });

      updateEdges.map(x => {
        const update = copyGraphDefaults.edges[x];
        const edge = cy.$id(x);
        edge.data(edgeToCytoscape(update));
        if (update.visible && edge.hasClass('hidden')) {
          edge.removeClass('hidden');
        } else if (!update.visible && !edge.hasClass('hidden')) {
          edge.addClass('hidden');
        }
      });
      /* end update */

      if (
        cy.nodes().filter(x => x.position().x === 0 && x.position().y === 0)
          .length > 0
      ) {
        const numberNodes = cy.nodes().length as number;
        const width = (2000 / 60) * numberNodes;
        const height = (1000 / 60) * numberNodes;

        const x1 = (cy.width() - width) / 2;
        const y1 = (cy.height() - height) / 2;

        const layout = this.cy.elements().layout({
          name: 'cose',
          randomize: false,
          fit: false,
          animate: false,
          boundingBox: {
            x1,
            y1,
            w: width,
            h: height,
          },
          padding: 300,
        });

        layout.run();
      }

      /* selection color set */
      if (this.cytoGraph.selected && this.cytoGraph.selected.node) {
        const node = cy.$id(this.cytoGraph.selected.node);
        node.data('color', colorMap('selected', 'node'));
        const neigh = node.outgoers().union(node.incomers());
        neigh.forEach(ele => {
          if (ele.isNode()) {
            ele.data('color', colorMap('selectedsecondary', 'node'));
          }
          if (ele.isEdge()) {
            ele.data('color', colorMap('selectedsecondary', 'edge'));
            ele.data('width', graphDefaults.edge.width * 4);
          }
        });
      } else if (this.cytoGraph.selected && this.cytoGraph.selected.edge) {
        const edge = cy.$id(this.cytoGraph.selected.edge);
        edge.data('color', colorMap('selected', 'node'));
        edge.data('width', graphDefaults.edge.width * 4);
        const neigh = edge.connectedNodes();
        neigh.forEach(node => {
          node.data('color', colorMap('selectedsecondary', 'node'));
        });
      }
      cy.endBatch();

      /* end selection color set */
    },
    nodeTap(node: NodeSingular) {
      const data = node.data() as CytoNodeDefaults;
      if (data.children.length !== 0) {
        const children = data.children;
        const visibility = !this.cytoGraph.nodes[children[0]].visible;

        for (const child of data.children) {
          this.cytoGraph.nodes[child].visible = visibility;
        }
      } else {
        if (
          this.cytoGraph.selected &&
          this.cytoGraph.selected.node === data.id
        ) {
          this.cytoGraph.selected = undefined;
        } else {
          this.cytoGraph.selected = {
            node: data.id,
          };
        }
      }

      this.draw();
    },

    edgeTap(edge: EdgeSingular) {
      const data = edge.data() as CytoNodeDefaults;

      if (this.cytoGraph.selected && this.cytoGraph.selected.edge === data.id) {
        this.cytoGraph.selected = undefined;
      } else {
        this.cytoGraph.selected = {
          edge: data.id,
        };
      }
      this.draw();
    },
  },
  mounted() {
    this.cy = cytoscape({
      container: this.$el,
      layout: {
        name: 'preset',
      },
      style: [
        {
          selector: '.hidden',
          style: {
            visibility: 'hidden',
          },
        },
        {
          selector: 'node',
          style: {
            'background-color': 'data(color)',
            label: 'data(label)',
            width: 'data(radius)',
            height: 'data(radius)',
          },
        },
        {
          selector: 'edge',
          style: {
            'line-color': 'data(color)',
            width: 'data(width)',
          },
        },
        {
          selector: 'node[label]',
          style: {
            'text-background-color': '#e9eef3',
            'text-background-opacity': 1,
            'text-border-opacity': 1,
            'text-border-width': 1,
            'text-border-style': 'solid',
            'text-border-color': '#333',
            'text-background-padding': '3px',
            'text-margin-y': -5,
          },
        },
      ],
      minZoom: 0.1,
      maxZoom: 10,
    });

    const nodeTap = this.nodeTap;
    const edgeTap = this.edgeTap;
    this.cy.on('tap', 'node', function (this: NodeSingular) {
      nodeTap(this);
    });
    this.cy.on('tap', 'edge', function (this: EdgeSingular) {
      edgeTap(this);
    });
  },
});
</script>

<style scoped>
#cytoscape {
  width: 100%;
  height: 100%;
  overflow: hidden;
}
</style>
