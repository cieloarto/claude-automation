#!/bin/bash

# Claude QA専用機能スクリプト

# QA & テストチームを初期化
init_qa_team() {
    local qa_prompt="あなたはQA & テストチームリーダーです。

【役割】
1. テスト要件定義 (docs/tests/test-specifications.md)
2. 品質ゲートチェック (PR作成前の必須チェック)
3. 自動PR作成・レビュー承認
4. 全体統合テスト (develop branch)

【改良されたQAワークフロー】
📋 品質ゲートチェック (PR作成前):
- 開発チームからのチェック依頼を受信
- 単体テスト・統合テスト・品質チェック実行
- ✅合格 → 自動PR作成 + レビュー承認
- ❌不合格 → 具体的な修正指示で差し戻し

📋 全体統合テスト:
- develop branchの統合品質確認
- パフォーマンス・セキュリティ・E2Eテスト
- リリース可否判定

【品質ゲート基準】
✅ 単体テストカバレッジ 80%以上
✅ 統合テスト全件合格
✅ セキュリティスキャン合格
✅ パフォーマンス基準クリア
✅ ESLint/TypeScript エラーなし

【利用可能なコマンド】  
- 品質チェック: qa_quality_gate '<チーム>' '<ブランチ>'
- 差し戻し: qa_reject '<チーム>' '<理由>'
- PR作成+承認: qa_approve_and_create_pr '<ブランチ>' '<内容>'
- 全体テスト: qa_integration_test
- テスト要件作成: qa_create_test_spec '<要件>'

【報告形式】
- 品質ゲート: '[QA] 品質ゲート: チーム○ - ✅合格/❌不合格'
- 差し戻し: '[QA] 差し戻し: チーム○ - 修正必要項目: [具体的内容]'
- PR作成: '[QA] PR作成完了: #[PR番号] + レビュー承認済み'
- 全体テスト: '[QA] 統合テスト: develop branch - ✅合格/❌不合格'

QA & テストチーム準備完了です。"

    tmux send-keys -t "$QA_PANE" "$qa_prompt" C-m
}

# QA品質ゲートチェック（改良版）
qa_quality_gate() {
    local team_letter="$1"
    local branch_name="$2"

    local check_prompt="【品質ゲートチェック実行】
チーム: $team_letter
ブランチ: feature/$branch_name

以下のチェックを順次実行してください：

🔍 ステップ1: 基本チェック
cd $WORKSPACE_DIR/../$branch_name
git status  # ブランチ確認
git log --oneline -5  # コミット履歴確認

🧪 ステップ2: 単体テストチェック
npm test
npm run test:coverage
# カバレッジ80%以上必須

🔗 ステップ3: 統合テストチェック  
npm run test:integration
# 他のコンポーネントとの連携確認

🔒 ステップ4: セキュリティチェック
npm audit
npm run security:check
# 脆弱性チェック

⚡ ステップ5: パフォーマンステスト
npm run test:performance
# レスポンス時間・メモリ使用量確認

📊 ステップ6: コード品質チェック
npm run lint
npm run type-check
# ESLint・TypeScriptエラー確認

【判定処理】
全てのチェックが合格の場合:
  → qa_approve_and_create_pr '$branch_name' '[実装内容の説明]'

1つでも不合格の場合:
  → qa_reject '$team_letter' '[具体的な修正指示]'

【重要】
- 不合格の場合は具体的な修正方法を指示してください
- 合格の場合は自動でPR作成とレビュー承認を実行してください

品質ゲートチェックを開始してください。"

    tmux send-keys -t "$QA_PANE" "$check_prompt" C-m
    echo "🔍 品質ゲートチェック開始: チーム$team_letter, ブランチ: feature/$branch_name"
}

# QA差し戻し処理
qa_reject() {
    local team_letter="$1"
    local reason="$2"

    # チーム番号を取得（A=0, B=1, ...）
    local team_num=$(($(printf "%d" "'$team_letter") - 65))

    if [ "$team_num" -ge 0 ] && [ "$team_num" -lt "${#TEAM_PANES[@]}" ]; then
        local reject_prompt="【QA差し戻し】

品質ゲートチェック結果: ❌不合格

修正が必要な項目:
$reason

【修正後の手順】
1. 指摘事項を修正
2. 修正内容をコミット
3. 単体テストを再実行して合格確認
4. '[チーム$team_letter] 修正完了、QAチームに再チェック依頼' で報告

修正完了までPR作成は保留されます。
品質基準を満たすよう修正をお願いします。"

        tmux send-keys -t "${TEAM_PANES[$team_num]}" "$reject_prompt" C-m
        tmux send-keys -t "$QA_PANE" "[QA] 差し戻し: チーム$team_letter - 修正必要項目: $reason" C-m
        echo "❌ QA差し戻し: チーム$team_letter → $reason"
    else
        echo "❌ 無効なチーム文字: $team_letter"
    fi
}

# QA承認とPR作成（自動レビュー承認付き）
qa_approve_and_create_pr() {
    local branch_name="$1"
    local description="$2"

    local pr_prompt="【品質ゲート合格 → PR作成+承認】
ブランチ: feature/$branch_name
説明: $description

品質ゲート全項目合格を確認しました。
GitHub PRを作成し、QAレビュー承認を実行します。

【PR作成手順】
1. 認証確認:
   gh auth status

2. PR作成:
   gh pr create --title \"$description\" \\
                --body \"## 実装内容
$description

## 品質ゲート結果  
✅ 単体テスト: 全件合格（カバレッジ80%以上）
✅ 統合テスト: 合格
✅ セキュリティチェック: 合格
✅ パフォーマンステスト: 合格
✅ コード品質: ESLint/TypeScript エラーなし

## QAチェック
✅ 品質ゲート合格
✅ QAレビュー承認済み

## 次のアクション
- [x] QAレビュー完了
- [ ] マージ実行
\" \\
                --head feature/$branch_name \\
                --base main \\
                --reviewer qa-team

3. 作成されたPR番号を取得:
   PR_NUMBER=\$(gh pr list --head feature/$branch_name --json number --jq '.[0].number')

4. QAレビュー承認:
   gh pr review \$PR_NUMBER --approve --body \"QAチーム承認: 品質ゲート全項目合格確認済み\"

5. 完了報告:
   echo \"[QA] PR作成完了: #\$PR_NUMBER + QAレビュー承認済み\"

【実行してください】
上記の手順を実行し、PR作成とQA承認を完了してください。"

    tmux send-keys -t "$QA_PANE" "$pr_prompt" C-m
    echo "✅ QA承認 → PR作成+レビュー承認実行: feature/$branch_name"
}

# 全体統合テスト（develop branch）
qa_integration_test() {
    local integration_prompt="【全体統合テスト実行】
対象: develop branch

以下の統合テストを実行してください：

🔄 ステップ1: develop branch準備
cd $WORKSPACE_DIR
git checkout develop
git pull origin develop

🧪 ステップ2: 全体ビルドテスト
npm install
npm run build
# ビルドエラーがないか確認

🔗 ステップ3: 統合テスト実行
npm run test:integration
# 全コンポーネント連携テスト

🌐 ステップ4: E2Eテスト実行  
npm run test:e2e
# エンドツーエンドテスト

⚡ ステップ5: パフォーマンステスト
npm run test:performance
# システム全体のパフォーマンス確認

🔒 ステップ6: セキュリティテスト
npm run security:full-scan
# セキュリティ全体スキャン

📊 ステップ7: コード品質レポート
npm run quality:report
# 全体のコード品質確認

【判定結果報告】
全テスト合格: '[QA] 統合テスト: develop branch ✅全テスト合格 - リリース準備完了'
不合格項目有: '[QA] 統合テスト: develop branch ❌不合格 - 修正必要項目: [具体的内容]'

【重要】
- 結果をdocs/tests/integration-test-report.mdに記録してください
- 不合格の場合は具体的な修正指示を含めてください

全体統合テストを開始してください。"

    tmux send-keys -t "$QA_PANE" "$integration_prompt" C-m
    echo "🧪 全体統合テスト開始: develop branch"
}

# テスト要件作成
qa_create_test_spec() {
    local requirements="$1"

    local spec_prompt="【テスト要件定義作成】
要件: $requirements

docs/tests/test-specifications.md に以下の内容でテスト要件を定義してください：

## テスト要件定義

### 1. 単体テスト要件
- 各関数・メソッドのテストケース
- カバレッジ目標: 80%以上
- モック・スタブの使用方針

### 2. 統合テスト要件  
- コンポーネント間連携テスト
- API統合テスト
- データベース連携テスト

### 3. E2Eテスト要件
- ユーザーシナリオテスト
- 画面遷移テスト
- 入力値検証テスト

### 4. パフォーマンステスト要件
- レスポンス時間基準
- 同時アクセス数テスト
- メモリ使用量テスト

### 5. セキュリティテスト要件
- 脆弱性スキャン
- 認証・認可テスト
- 入力値検証テスト

### 6. 品質ゲート基準
- 各テストの合格基準
- 不合格時の対応手順
- エスカレーション基準

テスト要件定義を作成してください。"

    tmux send-keys -t "$QA_PANE" "$spec_prompt" C-m
    echo "📋 テスト要件定義作成開始"
}

# QA専用エイリアス
alias qa-check='qa_quality_gate'
alias qa-reject='qa_reject'
alias qa-approve='qa_approve_and_create_pr'
alias integration-test='qa_integration_test'
alias test-spec='qa_create_test_spec'
