<template>
  <div>
    <div class="row">
      <div class="col-6">
        <problem :id="problemId"></problem>
      </div>
      <div class="col-6" v-loading="answersLoading">
        <problem-mode-switch
          :problemId="problemId"
          :teamId="teamId"
          :answers="answers"></problem-mode-switch>
        <template v-for="answer in currentAnswers">
          <answer :value="answer" :reload="reload"></answer>
        </template>
        <div class="new-issue" v-show="!isAdmin && !confirming">
          <div class="answerExample" v-if="canAnswer">
            <h3>解答例</h3>
            <p>
              お疲れ様です。〇〇です。<br>
              問題 XXX の解答を送らせていただきます。
            </p>
            <p>
              この問題ではxxxxxが原因でトラブルが発生したと考えられました。<br>
              そのため、以下のように設定を変更し、○○が正しく動くことを確認いたしました。<br>
              確認のほどよろしくお願いします。
            </p>
            <p>
              1. /etc/hoge/hoo.bar の編集<br>
              'config.hoge'の項目をtrueへ変更
            </p>
            <p>
              2. …
            </p>
          </div>
          <simple-markdown-editor v-model="newAnswer"></simple-markdown-editor>
          <div class="tools">
            <button v-on:click="showConfirmation()" class="btn btn-success">解答投稿</button>
          </div>
          <div v-if="!canAnswer" class="overlay">
            {{ scoringCompleteTime | dateRelative }}に解答送信が可能になります。
          </div>
          <div v-if="!canPost" class="overlay">
            解答を送信してください。
          </div>
        </div>
        <div v-if="confirming" class="confirm">
          <p>以下の内容で解答を送信しますか？</p>
          <div class="markdown">
            <markdown :value="this.newAnswer"></markdown>
          </div>
          <div class="buttonWrapper">
            <button v-on:click="hideConfirmation()" class="btn btn-default">修正</button>
            <button v-on:click="postNewIssue()" class="btn btn-success">解答送信</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.new-issue {
  position: relative;
  padding: 2rem 0;
}

.answerExample {
  color: #aaa;
  border: 1px solid #ddd;
  margin: 20px 0;
  border-radius: 5px;
  padding: 10px 20px;
}

.answerExample h3 {
  border-bottom: 1px solid #ddd;
  padding: 5px 10px 3px;
}

.answerExample p {
  margin-bottom: 1.2rem;
}

.answereExaample p:last-child {
  margin-bottom: inherit;
}

.new-issue .overlay {
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(0, 0, 0, .3);
  z-index: 1;
  font-size: 1.5rem;
  text-align: center;
  padding-top: 15rem;
}

.confirm {
  background: white;
  padding: 0;
  text-align: left;
}

.confirm p {
  font-size: 1.2rem;
  text-align: left;
  padding: 10px 20px 5px;
  border-bottom: 1px solid #ed1848;
}

.confirm .markdown {
  border: 1px solid #ddd;
  border-radius: 5px;
  padding: 20px;
}

.confirm .buttonWrapper {
  text-align: right;
  padding: 10px 20px;
}
</style>

<script>
import { SET_TITLE } from '../store/'
import { API } from '../utils/Api'
import Problem from '../components/Problem'
import Answer from '../components/Answer'
import Markdown from '../components/Markdown'
import ProblemModeSwitch from '../components/ProblemModeSwitch'
import SimpleMarkdownEditor from '../components/SimpleMarkdownEditor'
import {
  Emit,
  PUSH_NOTIF,
  REMOVE_NOTIF
} from '../utils/EventBus'
import { dateRelative } from '../utils/Filters'
import { mapGetters } from 'vuex'

export default {
  name: 'problem-answers',
  components: {
    Problem,
    SimpleMarkdownEditor,
    Answer,
    ProblemModeSwitch,
    Markdown
  },
  filters: {
    dateRelative,
  },
  data () {
    return {
      newAnswer: '',
      currentDate: new Date(),
      confirming: false,
    }
  },
  asyncData: {
    answersDefault: [],
    answers () {
      return API.getTeamWithAnswersComments(this.teamId).then(res => res.answers)
    },
  },
  computed: {
    problemId () {
      return '' + this.$route.params.id;
    },
    teamId () {
      return '' + this.$route.params.team;
    },
    currentAnswers () {
      if (!this.answers) return [];
      return this.answers
        .filter(i => '' + i.problem_id === this.problemId)
        .filter(i => '' + i.team_id === this.teamId)
        // .filter(i => this.issueId === undefined || '' + i.id === this.issueId);
    },
    // 採点のディレイタイム(ms)
    delay () {
      return ((this.contest && this.contest.answer_reply_delay_sec) ? this.contest.answer_reply_delay_sec : 0) * 1000;
    },
    // 採点中のAnswers
    scoringAnswers () {
      return this.answers
        .filter(ans => `${ans.problem_id}` === this.problemId)
        .filter(ans => !ans.score)
    },
    // 回答可能かどうか
    canAnswer () {
      return this.scoringCompleteTime < new Date(this.currentDate).valueOf();
    },
    postingAnswers () {
      return this.answers
        .filter(ans => `${ans.problem_id}` === this.problemId)
        .filter(ans => !ans.completed)
    },
    // 投稿可能かどうか
    canPost () {
      return this.postingAnswers.length === 0;
    },
    // 採点が完了する時間(ms)
    scoringCompleteTime () {
      return this.scoringAnswers
        .reduce((p, n) => Math.max(p, new Date(n.created_at).valueOf() + this.delay), 0)
    },
    ...mapGetters([
      'contest',
      'isAdmin',
    ])
  },
  watch: {
    teamId () {
      this.asyncReload('answers');
    },
  },
  mounted () {
    this.$store.dispatch(SET_TITLE, '解答一覧');
    setInterval(() => {
      this.currentDate = new Date();
    }, 200)
  },
  destroyed () {
  },
  methods: {
    async postNewIssue () {
      try {
        Emit(REMOVE_NOTIF, msg => msg.key === 'answer');

        await API.postAnswer(this.problemId, this.newAnswer);

        this.newAnswer = '';
        this.confirming = false;
        this.reload();
        Emit(PUSH_NOTIF, {
          type: 'success',
          title: '投稿しました',
          detail: '',
          key: 'answer',
        });
      } catch (err) {
        console.error(err);
        Emit(PUSH_NOTIF, {
          type: 'error',
          title: '投稿に失敗しました',
          key: 'answer',
        });
      }
    },
    reload () {
      this.asyncReload();
    },
    showConfirmation () {
      this.confirming = true;
    },
    hideConfirmation () {
      this.confirming = false;
    }
  },
}
</script>
