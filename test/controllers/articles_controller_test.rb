require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @article = articles(:one)
  end

  test "top page lists articles with links to their details" do
    get root_path

    assert_response :success
    assert_select "h1", "投稿一覧"
    assert_select "a[href=?]", new_article_path, text: "新規投稿"
    assert_select "table.articles-table th", text: "タイトル"
    assert_select "table.articles-table th", text: "投稿内容"
    Article.order(:id).each_with_index do |article, index|
      assert_select "tbody tr:nth-child(#{index + 1})" do
        assert_select "a[href=?]", article_path(article), text: article.title
        assert_select "td", text: article.content
      end
    end
  end

  test "new page provides a posting form and a link to the list" do
    get new_article_path

    assert_response :success
    assert_select "h1", "新規投稿"
    assert_select "form[action=?][method=post]", articles_path do
      assert_select "input[name='article[title]']"
      assert_select "textarea[name='article[content]']"
      assert_select "input[type=submit][value='投稿']"
    end
    assert_select "a[href=?]", articles_path, text: "一覧画面に戻る"
  end

  test "posting redirects to the list and displays the new article and success message" do
    assert_difference "Article.count", 1 do
      post articles_path, params: { article: { title: "仮タイトル4", content: "仮投稿4" } },
        headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
    end

    assert_response :see_other
    assert_redirected_to articles_path
    follow_redirect!
    assert_select ".flash-success", "新規投稿しました。"
    assert_select "tbody tr:last-child" do
      assert_select "a[href=?]", article_path(Article.order(:id).last), text: "仮タイトル4"
      assert_select "td", text: "仮投稿4"
    end
  end

  test "details provide editing and list links and a delete form" do
    get article_path(@article)

    assert_response :success
    assert_select "h1", "投稿詳細"
    assert_select "a[href=?]", edit_article_path(@article), text: "投稿編集へ遷移"
    assert_select "a[href=?]", articles_path, text: "一覧画面へ戻る"
    assert_select "form[action=?][method=post]", article_path(@article) do
      assert_select "input[name=_method][value=delete]"
      assert_select "button", "削除ボタン"
    end
  end

  test "edit page has existing values and links back to the same article" do
    get edit_article_path(@article)

    assert_response :success
    assert_select "h1", "投稿編集"
    assert_select "input[name='article[title]'][value=?]", @article.title
    assert_select "textarea[name='article[content]']", @article.content
    assert_select "input[type=submit][value='投稿更新']"
    assert_select "a[href=?]", article_path(@article), text: "投稿詳細へ戻る"
  end

  test "updating redirects to the list with the updated content and success message" do
    patch article_path(@article), params: { article: { title: "変更後のタイトル", content: "変更後の内容" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    assert_response :see_other
    assert_redirected_to articles_path
    assert_equal "変更後の内容", @article.reload.content
    follow_redirect!
    assert_select ".flash-success", "投稿を更新しました。"
    assert_select "a[href=?]", article_path(@article), text: "変更後のタイトル"
    assert_select "td", text: "変更後の内容"
  end

  test "deleting redirects to the list with a deletion message" do
    assert_difference "Article.count", -1 do
      delete article_path(@article)
    end

    assert_response :see_other
    assert_redirected_to articles_path
    follow_redirect!
    assert_select ".flash-delete", "投稿を削除しました。"
    assert_select "a[href=?]", article_path(@article), count: 0
  end
end
