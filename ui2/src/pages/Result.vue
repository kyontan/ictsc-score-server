<template>
  <div>
    <h1>Result</h1>
    <graph
      title="タイトル"
      class="graph access"
      :graph-data="result"
      :height="500"
      :notfound="false"
      v-loading="asyncLoading"></graph>
    <div class="list">
      <div v-for="item in result" class="item">
        <i class="tag" :style="{ background: item.color }"></i> {{ item.name }}
      </div>
    </div>
    <pre>{{ result }}</pre>
  </div>
</template>

<style scoped>
.tag {
  display: inline-block;
  width: 1em;
  height: 1em;
}
.item {
  display: inline-block;
  margin: 0 .5rem;
}
</style>

<script>
import { SET_TITLE } from '../store/'
import Graph from '../components/Graph'
import { API } from '../utils/Api'
import * as d3 from 'd3';
import { latestAnswer } from '../utils/Filters'

window.d3 = d3;

export default {
  name: 'result',
  components: {
    Graph,
  },
  data () {
    return {
    }
  },
  asyncData: {
    teamsDefault: [],
    teams () {
      return API.getTeamsWithScore();
    },
  },
  computed: {
    result () {
      return this.teams.map((t, i) => {
        var completedAnswers = t.answers
          .filter(ans => ans.completed_at && ans.completed);
        // 積算の点数を計算する関数
        var getPileSubtotal = (ans, date) => ((e) => e.score ? e.score.subtotal_point : 0)(
          latestAnswer(ans.filter(a => new Date(a.completed_at).valueOf() <= new Date(date).valueOf())))
        var answers = completedAnswers
          .map(ans => ({
            problem: ans.problem_id,
            subtotal: ans.score && ans.score.subtotal_point,
            total: getPileSubtotal(completedAnswers, ans.completed_at),
            date: new Date(ans.completed_at),
          }))
          .sort((a, b) => new Date(a.date).valueOf() - new Date(b.date).valueOf())
        return Object.assign({}, t, {
          answers: answers,
          color: d3.schemeCategory20[i],
        });
      })
    },
  },
  watch: {
  },
  mounted () {
    this.$store.dispatch(SET_TITLE, 'ページ名');
  },
  destroyed () {
  },
  methods: {
  },
}
</script>

