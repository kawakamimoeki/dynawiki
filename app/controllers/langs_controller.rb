class LangsController < ApplicationController
  include ActionView::RecordIdentifier

  def show
    @lang = Language.find_by(name: params[:lang])
    if @lang.name == "ja"
      @randoms = [
        "日本の伝統工芸品",
        "世界の奇妙な祭り",
        "古代文明の失われた都市",
        "未来のテクノロジー予測",
        "珍しい動物とその生態",
        "歴史に残る名言集",
        "音楽のジャンルとその特徴",
        "映画の名シーン解説",
        "世界の美しい景勝地",
        "有名な未解決事件"
      ]
    else
      @randoms = [
        "Traditional Japanese Crafts",
        "Strange Festivals Around the World",
        "Lost Cities of Ancient Civilizations",
        "Future Technology Predictions",
        "Rare Animals and Their Habitats",
        "Famous Historical Quotes",
        "Genres of Music and Their Characteristics",
        "Iconic Movie Scenes Explained",
        "Beautiful Scenic Spots Around the World",
        "Famous Unsolved Mysteries"
      ]
    end
  end
end
