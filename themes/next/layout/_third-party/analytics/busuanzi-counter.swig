{% if theme.busuanzi_count.total_visitors %}
    <span class="site-uv" title="{{ __('footer.total_visitors') }}">
      <i class="fa fa-{{ theme.busuanzi_count.total_visitors_icon }}"></i>
      网站总访客数 <span class="busuanzi-value" id="busuanzi_value_site_uv"></span> 人次. |
    </span>
  {% endif %}

  {% if theme.busuanzi_count.total_views %}
    <span class="site-pv" title="{{ __('footer.total_views') }}">
      &nbsp;<i class="fa fa-{{ theme.busuanzi_count.total_views_icon }}"></i>
      总访问量 <span class="busuanzi-value" id="busuanzi_value_site_pv"></span> 次.
    </span>
{% endif %}
