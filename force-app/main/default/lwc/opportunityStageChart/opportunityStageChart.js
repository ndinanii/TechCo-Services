// This is the component's brain. It fetches data from our Apex method and prepares it for the chart.

import { LightningElement, wire } from "lwc";
import getOpportunityCountsByStage from "@salesforce/apex/AccountViewController.getOpportunityCountsByStage";

// Define a list of colors for the chart bars
const CHART_COLORS = [
  "#1f77b4",
  "#ff7f0e",
  "#2ca02c",
  "#d62728",
  "#9467bd",
  "#8c564b",
  "#e377c2",
  "#7f7f7f",
  "#bcbd22",
  "#17becf"
];

export default class OpportunityStageChart extends LightningElement {
  chartData;
  error;

  // Use the @wire adapter to call the Apex method and get data.
  @wire(getOpportunityCountsByStage)
  wiredOppCounts({ error, data }) {
    if (data) {
      const totalOpportunities = data.reduce(
        (acc, stage) => acc + stage.count,
        0
      );

      this.chartData = data.map((stage, index) => {
        const percentage =
          totalOpportunities > 0 ? (stage.count / totalOpportunities) * 100 : 0;
        return {
          stage: stage.stage,
          count: stage.count,
          style: `width: ${percentage}%; background-color: ${CHART_COLORS[index % CHART_COLORS.length]};`
        };
      });
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.chartData = undefined;
    }
  }
}
